import socket
import AESCipher
import json
import ast

_key = 'IdontknowtheEncryptionKey'
_host = "206.189.163.242"
_port = 8080

def get_rsp(address,msg):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    print address
    sock.connect(address)
    rsp = ''
    sock.send(msg)
    while True:
        # This is the 'blocking' call in this synchronous program.
        # The recv() method will block for an indeterminate period
        # of time waiting for bytes to be received from the server.

        data = sock.recv(1024)

        if not data:
            sock.close()
            break

        rsp += data

    return rsp

#json dumps dict
#Encrypt and send
#recieve msg, decrypt
#Convert to dict
def connectToServer(host,port,msg):
    Cipher = AESCipher.AESCipher(_key)
    encMsg = Cipher.encrypt(json.dumps(msg))
    address = (host,port)
    encRsp = get_rsp(address,encMsg)
    decRsp = Cipher.decrypt(encRsp)
    print decRsp
    try:
        rsp = ast.literal_eval(decRsp)
    except:
        rsp = {}
        rsp['rsp'] = 'ERROR UNABLE TO CONVERT TO DICT'

    return rsp

def connectNokeToServer(session,mac):
    msg = ast.literal_eval('{"function":"Noke_Unlock","session":"' + str(session) + '","mac":"' + str(mac) + '"}')
    Cipher = AESCipher.AESCipher(_key)
    encMsg = Cipher.encrypt(json.dumps(msg))
    address = (_host,_port)
    encRsp = get_rsp(address,encMsg)
    decRsp = Cipher.decrypt(encRsp)
    print decRsp
    try:
        rsp = ast.literal_eval(decRsp)
        commands = rsp['data']["commands"]
    except:
        rsp = {}
        rsp['rsp'] = 'ERROR UNABLE TO CONVERT TO DICT'
        commands = "Acces Denied"

    return commands

def connectToGpy(host,port,msg):
    address = (host,port)
    rspString = get_rsp(address,msg)
    try:
        rsp = ast.literal_eval(rspString)
    except:
        rsp = {}
        rsp['rsp'] = 'ERROR UNABLE TO CONVERT TO DICT'

    return rsp