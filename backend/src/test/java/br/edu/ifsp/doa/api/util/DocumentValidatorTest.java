package br.edu.ifsp.doa.api.util;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class DocumentValidatorTest {
    @Test
    void cpf() {
        assertTrue(DocumentValidator.isValidCpf("52998224725"));
        assertFalse(DocumentValidator.isValidCpf("52998224726"));
        assertFalse(DocumentValidator.isValidCpf("11111111111"));
        assertFalse(DocumentValidator.isValidCpf("123"));
    }

    @Test
    void cnpj() {
        assertTrue(DocumentValidator.isValidCnpj("11222333000181"));
        assertTrue(DocumentValidator.isValidCnpj("12345678000195"));
        assertFalse(DocumentValidator.isValidCnpj("11222333000182"));
        assertFalse(DocumentValidator.isValidCnpj("00000000000000"));
    }

    @Test
    void digits() {
        assertEquals("52998224725", DocumentValidator.digits("529.982.247-25"));
        assertEquals("", DocumentValidator.digits(null));
    }

    @Test
    void geo() {
        assertNull(GeoUtils.distanceKm(null, 1.0, 2.0, 3.0));
        assertEquals(0.0, GeoUtils.distanceKm(-22.95, -46.54, -22.95, -46.54));
        // Bragança Paulista -> São Paulo: cerca de 70 km em linha reta
        double km = GeoUtils.distanceKm(-22.9527, -46.5419, -23.5505, -46.6333);
        assertTrue(km > 60 && km < 80, "distância fora do esperado: " + km);
    }
}
