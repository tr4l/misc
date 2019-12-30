import java.nio.charset.StandardCharsets;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.crypto.Cipher;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class MavenDecoder {
    private static final Pattern ENCRYPTED_STRING_PATTERN = Pattern.compile(".*?[^\\\\]?\\{(.*?[^\\\\])\\}.*");
    private static final int SALT_SIZE = 8;
    private static final int SPICE_SIZE = 16;
    private static final String DIGEST_ALG = "SHA-256";
    private static final String KEY_ALG = "AES";
    private static final String CIPHER_ALG = "AES/CBC/PKCS5Padding";

    private static Cipher createCipher(final byte[] pwdAsBytes, byte[] salt, final int mode)
            throws NoSuchAlgorithmException, NoSuchPaddingException, InvalidKeyException,
            InvalidAlgorithmParameterException {
        MessageDigest digester;
        digester = MessageDigest.getInstance(DIGEST_ALG);
        digester.reset();
        byte[] keyAndIv = new byte[SPICE_SIZE * 2];

        if (salt == null || salt.length == 0) {
            salt = null;
        }

        byte[] result;
        int currentPos = 0;

        while (currentPos < keyAndIv.length) {
            digester.update(pwdAsBytes);

            if (salt != null) {
                digester.update(salt, 0, 8);
            }
            result = digester.digest();
            int stillNeed = keyAndIv.length - currentPos;

            if (result.length > stillNeed) {
                byte[] b = new byte[stillNeed];
                System.arraycopy(result, 0, b, 0, b.length);
                result = b;
            }

            System.arraycopy(result, 0, keyAndIv, currentPos, result.length);
            currentPos += result.length;

            if (currentPos < keyAndIv.length) {
                // Next round starts with a hash of the hash.
                digester.reset();
                digester.update(result);
            }
        }

        byte[] key = new byte[SPICE_SIZE];
        byte[] iv = new byte[SPICE_SIZE];
        System.arraycopy(keyAndIv, 0, key, 0, key.length);
        System.arraycopy(keyAndIv, key.length, iv, 0, iv.length);
        Cipher cipher = Cipher.getInstance(CIPHER_ALG);

        cipher.init(mode, new SecretKeySpec(key, KEY_ALG), new IvParameterSpec(iv));
        return cipher;
    }

    private static String decodeMasterPassword(String encodedMasterPassword) {
        // The "master" is protected with a hardcoded string "settings.security". That should probably the "path" of the
        // settings instead...
        return decryptDecorated(encodedMasterPassword,
                "settings.security"/* DefaultSecDispatcher.SYSTEM_PROPERTY_SEC_LOCATION */);
    }

    private static String decrypt(final String str, final String passPhrase) {
        if (str == null || str.length() < 1) {
            return str;
        }

        return decrypt64(str, passPhrase);
    }

    private static String decrypt64(final String encryptedText, final String password) {
        try {
            byte[] allEncryptedBytes = Base64.getDecoder().decode((encryptedText.getBytes()));
            int totalLen = allEncryptedBytes.length;
            byte[] salt = new byte[SALT_SIZE];
            System.arraycopy(allEncryptedBytes, 0, salt, 0, SALT_SIZE);
            byte padLen = allEncryptedBytes[SALT_SIZE];
            byte[] encryptedBytes = new byte[totalLen - SALT_SIZE - 1 - padLen];
            System.arraycopy(allEncryptedBytes, SALT_SIZE + 1, encryptedBytes, 0, encryptedBytes.length);
            Cipher cipher = createCipher(password.getBytes(StandardCharsets.UTF_8), salt, Cipher.DECRYPT_MODE);
            byte[] clearBytes = cipher.doFinal(encryptedBytes);
            String clearText = new String(clearBytes, StandardCharsets.UTF_8);
            return clearText;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static String decryptDecorated(final String str, final String passPhrase) {
        if (str == null || str.length() < 1) {
            return str;
        }

        if (isEncryptedString(str)) {
            return decrypt(unDecorate(str), passPhrase);
        }
        throw new RuntimeException("Not Decorated");
    }

    private static boolean isEncryptedString(final String str) {
        if (str == null || str.length() < 1) {
            return false;
        }

        Matcher matcher = ENCRYPTED_STRING_PATTERN.matcher(str);

        return matcher.matches() || matcher.find();
    }

    public static void main(String... args) throws Exception {

        printPasswords(args[0], args[1]);
    }

    private static void printPasswords(String decoratedMaster, String decoratedPass) {

        String plainTextMasterPassword = decodeMasterPassword(decoratedMaster);
        System.out.printf("Master password is : %s%n", plainTextMasterPassword);

        String plainTextServerPassword = decryptDecorated(decoratedPass, plainTextMasterPassword);
        System.out.printf("Password : %s%n", plainTextServerPassword);
    }

    private static String unDecorate(final String str) {
        Matcher matcher = ENCRYPTED_STRING_PATTERN.matcher(str);

        if (matcher.matches() || matcher.find()) {
            return matcher.group(1);
        } else {
            throw new RuntimeException("Not Decorated");
        }
    }

}
