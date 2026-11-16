package br.edu.ifsp.doa.api;

import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

/** Testes de fluxo ponta a ponta com o banco H2 e os dados de demonstração. */
@SpringBootTest
@AutoConfigureMockMvc
class DoaFlowTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper om;

    // ---------- helpers ----------

    private ResultActions doPost(String url, String token, Object body) throws Exception {
        var req = post(url).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body));
        if (token != null) req.header("Authorization", "Bearer " + token);
        return mvc.perform(req);
    }

    private ResultActions doPut(String url, String token, Object body) throws Exception {
        var req = put(url).contentType(MediaType.APPLICATION_JSON).content(om.writeValueAsString(body));
        return mvc.perform(req.header("Authorization", "Bearer " + token));
    }

    private ResultActions doGet(String url, String token) throws Exception {
        return mvc.perform(get(url).header("Authorization", "Bearer " + token));
    }

    private JsonNode json(ResultActions r) throws Exception {
        return om.readTree(r.andReturn().getResponse().getContentAsString());
    }

    private String login(String email, String password) throws Exception {
        return json(doPost("/api/auth/login", null, Map.of("email", email, "password", password))
            .andExpect(status().isOk())).get("token").asText();
    }

    private long categoryId(String token, String name) throws Exception {
        for (JsonNode c : json(doGet("/api/categories", token).andExpect(status().isOk()))) {
            if (c.get("name").asText().equals(name)) return c.get("id").asLong();
        }
        throw new IllegalStateException("categoria não encontrada: " + name);
    }

    private long createDonation(String donorToken, long categoryId, String description) throws Exception {
        Map<String, Object> body = Map.of(
            "categoryId", categoryId, "description", description, "quantity", 10, "unit", "kg",
            "expiresAt", LocalDate.now().plusDays(5).toString(), "storageConditions", "Ambiente");
        return json(doPost("/api/donations", donorToken, body).andExpect(status().isCreated())).get("id").asLong();
    }

    // ---------- autenticação ----------

    @Test
    void semTokenRetorna401() throws Exception {
        mvc.perform(get("/api/donations/mine")).andExpect(status().isUnauthorized());
    }

    @Test
    void loginInvalidoRetorna401() throws Exception {
        doPost("/api/auth/login", null, Map.of("email", "admin@doa.com", "password", "errada"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void bloqueiaContaAposTresTentativasErradas() throws Exception {
        String email = "bloqueio-" + UUID.randomUUID() + "@doa.com";
        doPost("/api/auth/register", null, Map.of("email", email, "password", "senha123", "role", "DONOR"))
            .andExpect(status().isCreated());
        for (int i = 0; i < 3; i++) {
            doPost("/api/auth/login", null, Map.of("email", email, "password", "errada"))
                .andExpect(status().isUnauthorized());
        }
        doPost("/api/auth/login", null, Map.of("email", email, "password", "senha123"))
            .andExpect(status().isForbidden());
    }

    @Test
    void cadastroPublicoNaoCriaAdmin() throws Exception {
        doPost("/api/auth/register", null, Map.of("email", "x-" + UUID.randomUUID() + "@doa.com",
            "password", "senha123", "role", "ADMIN")).andExpect(status().isForbidden());
    }

    @Test
    void logoutInvalidaOToken() throws Exception {
        String token = login("doador@doa.com", "doador123");
        mvc.perform(post("/api/auth/logout").header("Authorization", "Bearer " + token))
            .andExpect(status().isNoContent());
        doGet("/api/donations/mine", token).andExpect(status().isUnauthorized());
    }

    // ---------- permissões ----------

    @Test
    void doadorNaoCriaCategoria() throws Exception {
        String donor = login("doador@doa.com", "doador123");
        doPost("/api/categories", donor, Map.of("name", "Nova")).andExpect(status().isForbidden());
    }

    @Test
    void categoriaEmUsoNaoPodeSerExcluida() throws Exception {
        String admin = login("admin@doa.com", "admin123");
        long id = categoryId(admin, "Verduras e legumes");
        mvc.perform(delete("/api/categories/" + id).header("Authorization", "Bearer " + admin))
            .andExpect(status().isConflict());
    }

    // ---------- fluxo da doação ----------

    @Test
    void doacaoDoCadastroAoEstoque() throws Exception {
        String donor = login("doador@doa.com", "doador123");
        String inst = login("ong@doa.com", "ong123");
        long id = createDonation(donor, categoryId(donor, "Frutas"), "Mangas do sítio " + UUID.randomUUID());

        doGet("/api/donations?radiusKm=100", inst).andExpect(status().isOk())
            .andExpect(jsonPath("$[*].id", hasItem((int) id)));

        doPost("/api/donations/" + id + "/request", inst, Map.of()).andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("RESERVED"));

        // reservada: o doador não edita mais
        doPut("/api/donations/" + id, donor, Map.of(
            "categoryId", categoryId(donor, "Frutas"), "description", "Outra", "quantity", 1, "unit", "kg",
            "expiresAt", LocalDate.now().plusDays(3).toString())).andExpect(status().isConflict());

        doPost("/api/donations/" + id + "/confirm-delivery", inst, Map.of()).andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("DELIVERED"));

        doGet("/api/stock", inst).andExpect(status().isOk());
        doGet("/api/impact", donor).andExpect(status().isOk())
            .andExpect(jsonPath("$.deliveredCount").exists());
    }

    @Test
    void limiteDeCincoSolicitacoesAtivas() throws Exception {
        String donor = login("doador@doa.com", "doador123");
        String inst = login("ong@doa.com", "ong123");
        long cat = categoryId(donor, "Bebidas");

        // o seed já deixa 1 reserva ativa; completa até 5
        int ativas = 0;
        for (JsonNode d : json(doGet("/api/donations/requested", inst).andExpect(status().isOk()))) {
            if ("RESERVED".equals(d.get("status").asText())) ativas++;
        }
        List<Long> reserved = new java.util.ArrayList<>();
        try {
            for (int i = ativas; i < 5; i++) {
                long id = createDonation(donor, cat, "Suco " + i + " " + UUID.randomUUID());
                doPost("/api/donations/" + id + "/request", inst, Map.of()).andExpect(status().isOk());
                reserved.add(id);
            }
            long extra = createDonation(donor, cat, "Suco extra " + UUID.randomUUID());
            doPost("/api/donations/" + extra + "/request", inst, Map.of()).andExpect(status().isConflict());
        } finally {
            // libera as reservas criadas aqui para não interferir nos outros testes
            for (long id : reserved) {
                doPut("/api/donations/" + id + "/cancel", donor, Map.of());
            }
        }
    }

    @Test
    void doacaoVencidaERejeitada() throws Exception {
        String donor = login("doador@doa.com", "doador123");
        doPost("/api/donations", donor, Map.of(
            "categoryId", categoryId(donor, "Frutas"), "description", "Vencida", "quantity", 1, "unit", "kg",
            "expiresAt", LocalDate.now().minusDays(1).toString())).andExpect(status().isBadRequest());
    }

    // ---------- N:N instituição <-> categoria ----------

    @Test
    void instituicaoSoVeESolicitaCategoriasQueAceita() throws Exception {
        String admin = login("admin@doa.com", "admin123");
        String donor = login("doador@doa.com", "doador123");

        // nova instituição que aceita apenas "Bebidas"
        String email = "ong-bebidas-" + UUID.randomUUID() + "@doa.com";
        String instToken = json(doPost("/api/auth/register", null,
            Map.of("email", email, "password", "senha123", "role", "INSTITUTION"))
            .andExpect(status().isCreated())).get("token").asText();

        long bebidas = categoryId(admin, "Bebidas");
        long instId = json(doPost("/api/institutions", instToken, Map.of(
            "name", "ONG Só Bebidas", "cnpj", "12345678000195", "address", "Rua A, 1", "city", "Atibaia",
            "areaOfActivity", "Distribuição", "storageCapacityKg", 100, "categoryIds", List.of(bebidas)))
            .andExpect(status().isCreated())).get("id").asLong();

        // ainda pendente: não pode buscar
        doGet("/api/donations", instToken).andExpect(status().isForbidden());

        doPut("/api/institutions/" + instId + "/approve", admin, Map.of()).andExpect(status().isOk());

        long frutaId = createDonation(donor, categoryId(donor, "Frutas"), "Uvas " + UUID.randomUUID());
        long sucoId = createDonation(donor, bebidas, "Suco de uva " + UUID.randomUUID());

        doGet("/api/donations?radiusKm=100", instToken).andExpect(status().isOk())
            .andExpect(jsonPath("$[*].id", hasItem((int) sucoId)))
            .andExpect(jsonPath("$[*].id", not(hasItem((int) frutaId))));

        doPost("/api/donations/" + frutaId + "/request", instToken, Map.of()).andExpect(status().isConflict());
        doPost("/api/donations/" + sucoId + "/request", instToken, Map.of()).andExpect(status().isOk());
    }

    @Test
    void instituicaoPrecisaAceitarAoMenosUmaCategoria() throws Exception {
        String email = "ong-vazia-" + UUID.randomUUID() + "@doa.com";
        String token = json(doPost("/api/auth/register", null,
            Map.of("email", email, "password", "senha123", "role", "INSTITUTION"))
            .andExpect(status().isCreated())).get("token").asText();
        doPost("/api/institutions", token, Map.of(
            "name", "ONG X", "cnpj", "11222333000181", "address", "Rua A, 1", "city", "Atibaia",
            "areaOfActivity", "Distribuição", "storageCapacityKg", 100, "categoryIds", List.of()))
            .andExpect(status().isBadRequest());
    }

    // ---------- fotos da doação ----------

    private static final byte[] PNG_MINIMO = {
        (byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0, 0, 0, 0, 0};

    private ResultActions upload(String url, String token, MockMultipartFile file) throws Exception {
        return mvc.perform(multipart(url).file(file).header("Authorization", "Bearer " + token));
    }

    @Test
    void fotoDaDoacaoEnviaListaServeEExclui() throws Exception {
        String donor = login("doador@doa.com", "doador123");
        String inst = login("ong@doa.com", "ong123");
        long id = createDonation(donor, categoryId(donor, "Frutas"), "Bananas " + UUID.randomUUID());

        var png = new MockMultipartFile("file", "foto.png", "image/png", PNG_MINIMO);
        String url = json(upload("/api/donations/" + id + "/photos", donor, png)
            .andExpect(status().isCreated())).get("url").asText();

        // a doação passa a trazer a foto; a instituição também enxerga
        doGet("/api/donations/" + id, inst).andExpect(status().isOk())
            .andExpect(jsonPath("$.photoUrls[0]").value(url));

        // a imagem é pública (o app a carrega sem cabeçalho) e volta com o tipo certo
        mvc.perform(get(url)).andExpect(status().isOk())
            .andExpect(content().contentType("image/png"));

        // arquivo que não é imagem é recusado, mesmo declarando image/png
        var falso = new MockMultipartFile("file", "x.png", "image/png", "isto não é imagem".getBytes());
        upload("/api/donations/" + id + "/photos", donor, falso).andExpect(status().isBadRequest());

        // instituição não envia foto
        upload("/api/donations/" + id + "/photos", inst, png).andExpect(status().isForbidden());

        String photoId = url.substring(url.lastIndexOf('/') + 1);
        mvc.perform(delete("/api/donations/" + id + "/photos/" + photoId).header("Authorization", "Bearer " + donor))
            .andExpect(status().isNoContent());
        mvc.perform(get(url)).andExpect(status().isNotFound());
    }
}
