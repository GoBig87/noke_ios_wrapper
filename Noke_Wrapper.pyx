cdef extern from "Noke_Wrapper_imp.h":
    ctypedef void (*callbackfunc)(const char *name, void *user_data)
    ctypedef const char* (*clientfunc)(const char *session, const char *mac, void *util)
    void request_Unlock(char* macChar, callbackfunc call_back, clientfunc client_func, void *user_data)

def requestUnlock(util,mac):

    cdef bytes mac_bytes = mac.encode('utf-8')

    request_Unlock(mac_bytes, callback, reqTokenFunc, <void*>util)

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef const char* reqTokenFunc(const char *session, const char *mac, void *util):
    #cdef char* rsp_char
    rsp = (<object> util).sendNokeMessage(session.decode('utf-8'),mac.decode('utf-8'))
    if rsp:
        #rsp_char = rsp.encode('utf-8')
        return rsp.encode('utf-8')