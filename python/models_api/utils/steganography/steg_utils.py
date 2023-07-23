from PIL import Image

def encode_image(medecin, patient, message):
    print(message)
    img = Image.open(f"./data/{medecin}/{patient}/prediction.jpg")
    width, height = img.size
    # Calcul de la taille maximal du message pouvant être codé dans l'image
    max_message_length = width * height * 3 // 8 - 1
    # Conversion du message en bloc de 8 bits par caractères
    binary_message = ''.join(format(ord(i), '08b') for i in message)
    # Ajouter un bit sentinel pour la fin du message et ajouter du padding au besoin
    sentinel_bit = '1'
    binary_message += sentinel_bit + '0' * ((8 - len(binary_message) % 8) % 8)
    # Vérifier que le message peut être encodé dans l'image
    if len(binary_message) > max_message_length:
        raise ValueError("Le message est trop long pour être encodé")
    # Réupérer les pixels de l'image
    pixels = list(img.getdata())
    # Parcourir et coder le message dans les canaux de ces LSBs
    message_index = 0
    for i, pixel in enumerate(pixels):
        # Terminer lorque le message est entier
        if message_index >= len(binary_message):
            break
        r, g, b = pixel
        if message_index < len(binary_message):
            r = (r & ~1) | int(binary_message[message_index])
            message_index += 1
        if message_index < len(binary_message):
            g = (g & ~1) | int(binary_message[message_index])
            message_index += 1
        if message_index < len(binary_message):
            b = (b & ~3) | int(binary_message[message_index]) << 1 | int(binary_message[message_index + 1])
            message_index += 2
        # Mettre à jour la valeur du pixel
        pixels[i] = (r, g, b)
    # Rajouter les pixels modifiés dans l'image
    img.putdata(pixels)
    img.save(f"./data/{medecin}/{patient}/prediction_encoded.png")


def decode_image(image_path):
    img = Image.open(image_path)
    # Obtient la liste des pixels de l'image
    pixels = list(img.getdata())
    # Initialise une chaîne vide pour stocker le message binaire caché dans les pixels
    binary_message = ""
    # Initialise une chaîne de bits sentinelle pour marquer la fin du message
    sentinel_bit = '1'
    # Initialise un booléen pour vérifier si le message est complet
    message_complete = False
    # Itère sur chaque pixel dans la liste de pixels
    for pixel in pixels:
        # Extrait les composantes rouge, verte et bleue du pixel
        r, g, b = pixel
        # Ajoute le bit de poids faible de r et g à la chaîne binaire
        binary_message += str(r & 1)
        binary_message += str(g & 1)
        # Ajoute le deuxième bit de poids faible de b et le bit de poids faible de b à la chaîne binaire
        binary_message += str((b & 2) >> 1)
        binary_message += str(b & 1)
        # Vérifie si les 9 derniers bits de la chaîne binaire correspondent à la chaîne sentinelle
        if binary_message[-9:] == sentinel_bit + "0" * 8:
            # Si c'est le cas, le message est complet, donc définit message_complete à True et interrompt la boucle
            message_complete = True
            break
    # Si le message n'est pas complet à la fin de la boucle, lève une exception
    if not message_complete:
        raise ValueError("No message found in image")
    # Supprime la chaîne sentinelle de la fin de la chaîne binaire
    binary_message = binary_message[:-9]
    # Convertit la chaîne binaire en une chaîne de caractères ASCII et retourne le message
    message = ""
    for i in range(0, len(binary_message), 8):
        message += chr(int(binary_message[i:i+8], 2))
    # Supprimer tout caractère nul à la fin du message et le retourner
    message = message.split("\x80")[0]
    return message

