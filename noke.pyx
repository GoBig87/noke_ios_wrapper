STUFF = "Hi"
import ast
from userClient import connectToServer
_host = '206.189.163.242'
_port = 8080

cdef extern from "NokeController.h":
    ctypedef void (*store_viewcontroller)(void *viewcontroller,void *util)
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void StartUnlock(char* name, char* macChar, callbackfunc call_back, clientfunc client_func,store_viewcontroller storeviewcontroller, void *user_data)

def requestUnlock(util,name,mac):
    cdef bytes name_bytes = name.encode('utf-8')
    cdef bytes mac_bytes  = mac.encode('utf-8')

    StartUnlock(name_bytes,mac_bytes, callback, reqTokenFunc, storeviewcontroller, <void*>util)

cdef void storeviewcontroller(void *viewcontroller,void *util):
    (<object> util).NokeViewController = (<object> viewcontroller)

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef const char* reqTokenFunc(const char *session, const char *mac, void *util):
    from libc.stdio cimport printf
    printf("%f\n", session)
    printf("%f\n", mac)
    sessionStr = (session.decode('utf-8'))
    macStr     = (mac.decode('utf-8'))
    printf("%f\n", sessionStr)
    printf("%f\n", macStr)
    rsp = (<object> util).sendNokeMessage(sessionStr,macStr)
    printf("%f\n", rsp)
    printf("%f\n",util)
    cdef bytes rsp_bytes = rsp.encode('utf-8')
    return rsp_bytes
    #rsp = (<object> util).sendNokeMessage((session.decode('utf-8')),(mac.decode('utf-8')))
    #if rsp:
    #    return rsp.encode('utf-8')