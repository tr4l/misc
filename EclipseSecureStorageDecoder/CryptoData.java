import java.util.Base64;

public class CryptoData {

	static final private char MODULE_ID_SEPARATOR = '\t'; // must not be a valid Base64 char

	/**
	 * Separates salt from the data; this must not be a valid Base64 character.
	 */
	static private final char SALT_SEPARATOR = ',';
	static private final char IV_SEPARATOR = ';';

	final private String moduleID;
	final private byte[] salt;
	final private byte[] iv;
	final private byte[] encryptedData;

	public CryptoData(String moduleID, byte[] salt, byte[] data, byte[] iv) {
		this.moduleID = moduleID;
		this.salt = salt;
		this.encryptedData = data;
		this.iv = iv;
	}

	public String getModuleID() {
		return moduleID;
	}

	public byte[] getSalt() {
		return salt;
	}

	public byte[] getData() {
		return encryptedData;
	}

	public byte[] getIV() {
		return iv;
	}

	public CryptoData(String data) throws Exception {
		// separate moduleID
		int pos = data.indexOf(MODULE_ID_SEPARATOR);
		String encrypted;
		if (pos == -1) { // invalid data format
			throw new Exception("Invalid data format");
		} else if (pos == 0) {
			moduleID = null;
			encrypted = data.substring(1);
		} else {
			moduleID = data.substring(0, pos);
			encrypted = data.substring(pos + 1);
		}

		// separate IV
		int ivPos = encrypted.indexOf(IV_SEPARATOR);
		if (ivPos != -1) {
			iv = Base64.getDecoder().decode(encrypted.substring(0, ivPos));
		} else { // this data does not provide an IV
			iv = null;
		}

		// separate salt and data
		int saltPos = encrypted.indexOf(SALT_SEPARATOR);
		if (saltPos != -1) {
			salt = Base64.getDecoder().decode(encrypted.substring(ivPos + 1, saltPos));
			encryptedData = Base64.getDecoder().decode(encrypted.substring(saltPos + 1));
		} else { // this is a "null" value
			if (encrypted.length() != 0) // double check that this is not a broken entry
				throw new Exception("nope");
			salt = null;
			encryptedData = null;
		}
	}

}

