package br.edu.ifsp.doa.api.util;

public final class DocumentValidator {
    private DocumentValidator() {}

    public static String digits(String value) {
        return value == null ? "" : value.replaceAll("\\D", "");
    }

    public static boolean isValidCpf(String d) {
        if (d == null || d.length() != 11 || d.matches("(\\d)\\1{10}")) return false;
        return check(d, 9) == d.charAt(9) - '0' && check(d, 10) == d.charAt(10) - '0';
    }

    private static int check(String d, int length) {
        int sum = 0;
        for (int i = 0; i < length; i++) {
            sum += (d.charAt(i) - '0') * (length + 1 - i);
        }
        int r = (sum * 10) % 11;
        return r == 10 ? 0 : r;
    }

    public static boolean isValidCnpj(String d) {
        if (d == null || d.length() != 14 || d.matches("(\\d)\\1{13}")) return false;
        int[] w1 = {5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int[] w2 = {6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        return cnpjDigit(d, w1) == d.charAt(12) - '0' && cnpjDigit(d, w2) == d.charAt(13) - '0';
    }

    private static int cnpjDigit(String d, int[] weights) {
        int sum = 0;
        for (int i = 0; i < weights.length; i++) {
            sum += (d.charAt(i) - '0') * weights[i];
        }
        int r = sum % 11;
        return r < 2 ? 0 : 11 - r;
    }
}
