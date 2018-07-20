STUFF = "Hi"
from libc.stdio cimport printf
from cpython.ref cimport Py_INCREF

cdef extern from "NokeController.h":
    ctypedef void (*store_viewcontroller)(void *viewcontroller,void *util)
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void StartUnlock(char* name, char* macChar, callbackfunc call_back, clientfunc client_func,store_viewcontroller storeviewcontroller, void *user_data, void *utilSendMessage)

class NokePadLock():
    def __init__(self,util):
        self.util = util

    def requestUnlock(self,name,mac):
        cdef bytes name_bytes = name.encode('utf-8')
        cdef bytes mac_bytes  = mac.encode('utf-8')
        StartUnlock(name_bytes,mac_bytes, callback, reqTokenFunc, storeviewcontroller, <void*>self.util, <void*>util.sendNokeMessage)

cdef void storeviewcontroller(void *viewcontroller,void *util):
    (<object> util).NokeViewController = (<object> viewcontroller)

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef const char* reqTokenFunc(const char *session, const char *mac, void *util):
    printf("%s\n", session)
    printf("%s\n", mac)
    sessionStr = (session.decode('utf-8'))
    macStr     = (mac.decode('utf-8'))
    rsp = (<object>util).sendNokeMessage(sessionStr,macStr)
    return rsp
    #rsp = (<object> util).NokeCallback
    #printf("%s\n", session)
    #printf("%s\n", mac)
    #printf("%s\n", rsp.encode('utf-8'))
    #return session
    # sessionStr = (session.decode('utf-8'))
    # macStr     = (mac.decode('utf-8'))
    # rsp = (<object> util).sendNokeMessage(sessionStr,macStr)
    # cdef bytes rsp_bytes = rsp.encode('utf-8')
    # printf("%s\n", rsp_bytes)
    #return rsp.encode('utf-8')
    #rsp = (<object> util).sendNokeMessage((session.decode('utf-8')),(mac.decode('utf-8')))
    #if rsp:
    #    return rsp.encode('utf-8')