STUFF = "Hi"
from libc.stdio cimport printf
from cpython.ref cimport Py_INCREF

cdef extern from "NokeController.h":
    ctypedef void (*store_viewcontroller)(void *viewcontroller,void *util)
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void StartUnlock(char* name, char* macChar, callbackfunc call_back, clientfunc client_func,store_viewcontroller storeviewcontroller, void *user_data, void *utilSendMessage)

def requestUnlock(util,name,mac):
    cdef bytes name_bytes = name.encode('utf-8')
    cdef bytes mac_bytes  = mac.encode('utf-8')
    Py_INCREF(util)
    StartUnlock(name_bytes,mac_bytes, callback, reqTokenFunc, storeviewcontroller, <void*>util, <void*>util.sendNokeMessage)

cdef void storeviewcontroller(void *viewcontroller,void *util):
    (<object> util).NokeViewController = (<object> viewcontroller)

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef const char* reqTokenFunc(const char *session, const char *mac, void *util):
    printf("%s\n", session)
    printf("%s\n", mac)
    sessionStr = (session.decode('utf-8'))
    macStr     = (mac.decode('utf-8'))
    rsp = PyObject_CallMethod((<object>util), "sendNokeMessage", "(s)", sessionStr,macStr);
    return rsp
