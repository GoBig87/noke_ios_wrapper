STUFF = "Hi"
from libc.stdio cimport printf
from cpython.ref cimport Py_INCREF
from libcpp cimport bool

cdef extern from "NokeController.h":
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void StartUnlock(char* name, char* macChar,lockState ,callbackfunc call_back, clientfunc client_func, void *user_data)
    void DisconnectLock(char* name, char* macChar)

class NokePadLock():
    def __init__(self,util):
        self.util = util

    def disconnectLock(self,name,mac):
        cdef bytes name_bytes = name.encode('utf-8')
        cdef bytes mac_bytes = mac.encode('utf-8')
        DisconnectLock(name_bytes,mac_bytes)

    def requestUnlock(self,name,mac,lockState):
        cdef bytes name_bytes = name.encode('utf-8')
        cdef bytes mac_bytes  = mac.encode('utf-8')
        StartUnlock(name_bytes,mac_bytes, lockState, callback, reqTokenFunc, <void*>self.util)


cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))


cdef const char* reqTokenFunc(const char *session, const char *mac, void *util) with gil:
    printf("%s\n", session)
    printf("%s\n", mac)
    (<object> util).NokeCallback = "Sending lock commands"
    printf("%s\n", mac)
    sessionStr = (session.decode('utf-8'))
    macStr     = (mac.decode('utf-8'))
    commands = (<object>util).sendNokeMessage(sessionStr,macStr)
    return commands.encode('utf-8')
