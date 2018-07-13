STUFF = "Hi"

cdef extern from "NokeViewController.h":
    ctypedef void (*store_viewcontroller)(NokeViewController *viewcontroller,void *util)
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void StartUnlock(char* name, char* macChar, callbackfunc call_back, clientfunc client_func, void *user_data)

def requestUnlock(util,name,mac):
    cdef bytes name_bytes = name.encode('utf-8')
    cdef bytes mac_bytes  = mac.encode('utf-8')

    StartUnlock(name_bytes,mac_bytes, callback, reqTokenFunc, store_viewcontroller, <void*>util)

cdef void store_viewcontroller(NokeViewController *viewcontroller,void *util):
    (< object > util).NokeViewController = viewcontroller

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef const char* reqTokenFunc(const char *session, const char *mac, void *util):
    #cdef char* rsp_char
    rsp = (<object> util).sendNokeMessage(session.decode('utf-8'),mac.decode('utf-8'))
    if rsp:
        #rsp_char = rsp.encode('utf-8')
        return rsp.encode('utf-8')