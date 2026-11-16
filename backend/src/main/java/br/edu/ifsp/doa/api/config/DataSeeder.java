package br.edu.ifsp.doa.api.config;

import br.edu.ifsp.doa.api.domain.*;
import br.edu.ifsp.doa.api.repository.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Sempre garante as categorias e um administrador. Com doa.seed.demo=true
 * (padrão local), cria também usuários e doações de exemplo.
 */
@Component
public class DataSeeder implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(DataSeeder.class);

    private final AppProperties props;
    private final PasswordEncoder encoder;
    private final UserRepository users;
    private final DonorRepository donors;
    private final InstitutionRepository institutions;
    private final FoodCategoryRepository categories;
    private final DonationRepository donations;
    private final StockItemRepository stock;
    private final MessageRepository messages;

    public DataSeeder(AppProperties props, PasswordEncoder encoder, UserRepository users, DonorRepository donors,
                      InstitutionRepository institutions, FoodCategoryRepository categories,
                      DonationRepository donations, StockItemRepository stock, MessageRepository messages) {
        this.props = props;
        this.encoder = encoder;
        this.users = users;
        this.donors = donors;
        this.institutions = institutions;
        this.categories = categories;
        this.donations = donations;
        this.stock = stock;
        this.messages = messages;
    }

    @Override
    @Transactional
    public void run(String... args) {
        seedCategories();
        seedAdmin();
        if (props.seed().demo() && !users.existsByEmailIgnoreCase("doador@doa.com")) {
            seedDemo();
        }
    }

    private void seedCategories() {
        if (categories.count() > 0) return;
        categories.saveAll(List.of(
            new FoodCategory("Frutas", "Frutas frescas"),
            new FoodCategory("Verduras e legumes", "Hortaliças e legumes"),
            new FoodCategory("Grãos e cereais", "Arroz, feijão, macarrão e similares"),
            new FoodCategory("Laticínios", "Leite, queijos e iogurtes"),
            new FoodCategory("Carnes", "Carnes, aves e peixes"),
            new FoodCategory("Padaria", "Pães, bolos e massas"),
            new FoodCategory("Refeições prontas", "Marmitas e preparos"),
            new FoodCategory("Bebidas", "Sucos, água e similares"),
            new FoodCategory("Outros", "Itens não classificados")));
    }

    private void seedAdmin() {
        if (users.existsByRole(UserRole.ADMIN)) return;
        createUser(props.seed().adminEmail(), props.seed().adminPassword(), UserRole.ADMIN);
        log.warn("Administrador criado ({}). Troque a senha padrão em produção!", props.seed().adminEmail());
    }

    private User createUser(String email, String password, UserRole role) {
        User u = new User();
        u.setEmail(email);
        u.setPasswordHash(encoder.encode(password));
        u.setRole(role);
        return users.save(u);
    }

    private Donor createDonor(User user, PersonType type, String name, String document, String city,
                              double lat, double lng) {
        Donor d = new Donor();
        d.setUser(user);
        d.setPersonType(type);
        d.setName(name);
        d.setDocument(document);
        d.setPhone("11999998888");
        d.setAddress("Rua Exemplo, 100");
        d.setCity(city);
        d.setLatitude(lat);
        d.setLongitude(lng);
        return donors.save(d);
    }

    private FoodCategory cat(String name) {
        return categories.findAllByOrderByNameAsc().stream()
            .filter(c -> c.getName().equals(name)).findFirst().orElseThrow();
    }

    private Donation donation(Donor donor, String category, String description, double qty, String unit,
                          int expiresInDays, String storage) {
        Donation d = new Donation();
        d.setDonor(donor);
        d.setCategory(cat(category));
        d.setDescription(description);
        d.setQuantity(qty);
        d.setUnit(unit);
        d.setExpiresAt(LocalDate.now().plusDays(expiresInDays));
        d.setStorageConditions(storage);
        return donations.save(d);
    }

    private void chat(Donation donation, User sender, String content, int minutesAgo) {
        Message m = new Message();
        m.setDonation(donation);
        m.setSender(sender);
        m.setContent(content);
        m.setSentAt(LocalDateTime.now().minusMinutes(minutesAgo));
        messages.save(m);
    }

    private void seedDemo() {
        // Bragança Paulista ≈ (-22.95, -46.54)
        User maria = createUser("doador@doa.com", "doador123", UserRole.DONOR);
        Donor mariaDonor = createDonor(maria, PersonType.INDIVIDUAL, "Maria Silva", "52998224725",
            "Bragança Paulista", -22.9519, -46.5419);

        User mercadoUser = createUser("mercado@doa.com", "mercado123", UserRole.DONOR);
        Donor mercado = createDonor(mercadoUser, PersonType.COMPANY, "Supermercado Bom Preço", "11222333000262",
            "Bragança Paulista", -22.9800, -46.5600);

        User esperancaUser = createUser("ong@doa.com", "ong123", UserRole.INSTITUTION);
        Institution esperanca = new Institution();
        esperanca.setUser(esperancaUser);
        esperanca.setName("Casa de Acolhida Esperança");
        esperanca.setCnpj("11222333000181");
        esperanca.setAddress("Av. Brasil, 500");
        esperanca.setCity("Bragança Paulista");
        esperanca.setAreaOfActivity("Distribuição de cestas básicas");
        esperanca.setStorageCapacityKg(800);
        esperanca.setStatus(InstitutionStatus.APPROVED);
        esperanca.setLatitude(-22.9400);
        esperanca.setLongitude(-46.5300);
        esperanca.setCategories(new HashSet<>(categories.findAll()));
        institutions.save(esperanca);

        User pendingUser = createUser("ong2@doa.com", "ong123", UserRole.INSTITUTION);
        Institution pending = new Institution();
        pending.setUser(pendingUser);
        pending.setName("ONG Pão Nosso");
        pending.setCnpj("45723174000110");
        pending.setAddress("Rua das Acácias, 42");
        pending.setCity("Atibaia");
        pending.setAreaOfActivity("Refeições comunitárias");
        pending.setStorageCapacityKg(300);
        pending.setStatus(InstitutionStatus.PENDING);
        pending.setCategories(new HashSet<>(List.of(cat("Refeições prontas"), cat("Padaria"))));
        institutions.save(pending);

        donation(mercado, "Verduras e legumes", "Caixas de hortaliças variadas", 20, "kg", 2, "Refrigerado");
        donation(mercado, "Frutas", "Bananas e maçãs", 35, "kg", 5, "Ambiente");
        donation(mercado, "Grãos e cereais", "Arroz tipo 1 (pacotes de 5 kg)", 50, "kg", 120, "Ambiente");
        donation(mercado, "Laticínios", "Iogurtes naturais", 40, "un", 6, "Refrigerado");
        donation(mercado, "Bebidas", "Sucos integrais", 24, "L", 30, "Ambiente");
        donation(mercado, "Refeições prontas", "Marmitas prontas", 30, "un", 1, "Refrigerado");
        donation(mariaDonor, "Frutas", "Laranjas do quintal", 10, "kg", 4, "Ambiente");
        // Doação já reservada, com conversa: permite testar o chat (WebSocket) sem passos extras.
        Donation paes = donation(mariaDonor, "Padaria", "Pães de forma", 8, "kg", 3, "Ambiente");
        paes.setStatus(DonationStatus.RESERVED);
        paes.setReservedBy(esperanca);
        paes.setReservedAt(LocalDateTime.now());
        donations.save(paes);
        chat(paes, esperancaUser, "Olá, Maria! Podemos retirar os pães hoje às 16h?", 10);
        chat(paes, maria, "Olá! Pode vir, estarei em casa até as 18h.", 5);

        log.info("Dados de demonstração criados (doador@doa.com, mercado@doa.com, ong@doa.com, ong2@doa.com).");
    }
}
