import java.io.File;
import java.io.FileReader;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;
import java.util.Map.Entry;
import java.util.Properties;
import java.util.Scanner;
import java.util.Set;

import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.PBEKeySpec;
import javax.crypto.spec.PBEParameterSpec;

public class EclipseSecureStorageDecoder {
	private final static String PATH_SEPARATOR = "/";
	
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security/src/org/eclipse/equinox/internal/security/storage/StorageUtils.java
	final private static String propertiesFileName = ".eclipse/org.eclipse.equinox.security/secure_storage"; //$NON-NLS-1$
	
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security/src/org/eclipse/equinox/internal/security/storage/SecurePreferencesRoot.java#L40	
	private static final String VERSION_KEY = "org.eclipse.equinox.security.preferences.version"; //$NON-NLS-1$
	private static final String VERSION_VALUE = "1"; //$NON-NLS-1$

	
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security/src/org/eclipse/equinox/internal/security/storage/friends/IStorageConstants.java#L19
	private final static String CIPHER_KEY = "org.eclipse.equinox.security.preferences.cipher"; //$NON-NLS-1$
	private final static String KEY_FACTORY_KEY = "org.eclipse.equinox.security.preferences.keyFactory"; //$NON-NLS-1$
	private final static String DEFAULT_CIPHER = "PBEWithMD5AndDES"; //$NON-NLS-1$
	private final static String DEFAULT_KEY_FACTORY = "PBEWithMD5AndDES"; //$NON-NLS-1$	
	
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security/src/org/eclipse/equinox/internal/security/storage/JavaEncryption.java#L51
	private final static int SALT_ITERATIONS = 10;
	
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security.win32.x86/src/org/eclipse/equinox/internal/security/win32/WinCrypto.java#L44
	private final static String WIN_PROVIDER_NODE = "/org.eclipse.equinox.secure.storage/windows64";
	private final static String PASSWORD_KEY = "encryptedPassword";

	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security.tests/src/org/eclipse/equinox/internal/security/tests/storage/WinPreferencesTest.java#L40
	static private final String WIN_64BIT_MODULE_ID = "org.eclipse.equinox.security.WindowsPasswordProvider64bit"; //$NON-NLS-1$
	
	public static void main(String[] args) throws Exception {

		String userHome = System.getProperty("user.home"); //$NON-NLS-1$
		File file = new File(userHome, propertiesFileName);
		if (!file.exists()) {
			System.out.println("Can't found secure storage at the default location: " + file.getAbsolutePath());
			return;
		}
		Properties prop = new Properties();
		FileReader fr = new FileReader(file);
		prop.load(fr);
		System.out.println(" - properties file loaded");
		
		String version = prop.getProperty(VERSION_KEY);
		if (version == null || !VERSION_VALUE.equalsIgnoreCase(version)) {
			System.out.println(" - not compatible");
			return;
		}
		String cipher = DEFAULT_CIPHER;
		String keyFactory = DEFAULT_KEY_FACTORY;
		
		if (prop.getProperty(CIPHER_KEY)!=null) {
			cipher = prop.getProperty(CIPHER_KEY);
			System.out.println(" - cipher found: " + cipher);
			
		}
		try {
			Cipher.getInstance(cipher);
		}catch (NoSuchAlgorithmException nsae) {
			System.out.println(" - cipher not supported on your system");
			return;
		}
		
		if (prop.getProperty(KEY_FACTORY_KEY)!=null) {
			keyFactory = prop.getProperty(KEY_FACTORY_KEY);
			System.out.println(" - key factory found: " + keyFactory);
		}
		try {
			SecretKeyFactory.getInstance(keyFactory);
		}catch (NoSuchAlgorithmException nsae) {
			System.out.println(" - key factory not supported on your system");
			return;
		}
		
		CryptoData cmaster = new CryptoData((String) prop.get(WIN_PROVIDER_NODE + PATH_SEPARATOR + PASSWORD_KEY));
		String master ="";
		if (cmaster.getData().length !=0) {
			System.out.println(" - master key found for win64 (DPAPI)");
			String data64 = new String(cmaster.getData());
			System.out.println("# Run the following in powershell to get the master key decrypted");
			System.out.println("Add-Type -AssemblyName System.Security;");
			System.out.println("$code=\"" + data64 + "\"");
			System.out.println("[Text.Encoding]::ASCII.GetString([Security.Cryptography.ProtectedData]::Unprotect([Convert]::FromBase64String($code), $null, 'CurrentUser'))");
			System.out.println("Type the result here:");
			Scanner in = new Scanner(System.in);
		    master = in.nextLine();
		    in.close();
		} else {
			System.out.println(" - master key not found. We will not be able to decrypt");

		}
		PBEKeySpec masterPBE = new PBEKeySpec(master.toCharArray());

		Set<Entry<Object, Object>> entries = prop.entrySet();
	    for (Entry<Object, Object> entry : entries) {
	    	String keyName = (String) entry.getKey();
	    	if (keyName.startsWith(PATH_SEPARATOR) && !keyName.startsWith("/org.eclipse.equinox.secure.storage")) {
	    		String value = (String) entry.getValue();
	    		CryptoData cryptoData = new CryptoData(value);
	    		String prefix = "clear";
	    		String data = new String(cryptoData.getData());
	    		if (WIN_64BIT_MODULE_ID.equalsIgnoreCase(cryptoData.getModuleID())) {
	    			
	    			byte[] out = internalDecrypt(masterPBE, cryptoData, cipher, keyFactory);
	    			if (out ==null) {
	    				// Base 64 of data for binary visibility
	    				data = Base64.getEncoder().encodeToString(data.getBytes());
	    				prefix = "crypted";
	    			}else {
	    				prefix = "decrypted";
	    				data = new String(out);
	    			}
	    		}
	    		System.out.println(keyName + "("+prefix+")> " + data );
	    		
	    	}
	    }

	}
	// From: https://github.com/eclipse/rt.equinox.bundles/blob/master/bundles/org.eclipse.equinox.security/src/org/eclipse/equinox/internal/security/storage/JavaEncryption.java#L166 
	// With some tweak
	private static byte[] internalDecrypt(PBEKeySpec master, CryptoData encryptedData, String cipherName, String keyFactoryName) {
		try {
			SecretKeyFactory keyFactory = SecretKeyFactory.getInstance(keyFactoryName);
			SecretKey key = keyFactory.generateSecret(master);

			IvParameterSpec ivParamSpec = null;
			if (encryptedData.getIV() != null) {
				ivParamSpec = new IvParameterSpec(encryptedData.getIV());
			}

			PBEParameterSpec entropy = null;
			if (ivParamSpec != null) {
				entropy = new PBEParameterSpec(encryptedData.getSalt(), SALT_ITERATIONS, ivParamSpec);
			} else {
				entropy = new PBEParameterSpec(encryptedData.getSalt(), SALT_ITERATIONS);
			}

			Cipher c = Cipher.getInstance(cipherName);
			c.init(Cipher.DECRYPT_MODE, key, entropy);

			byte[] result = c.doFinal(encryptedData.getData());
			return result;
		} catch (Exception e) {
			return null;
		}
	}
}

