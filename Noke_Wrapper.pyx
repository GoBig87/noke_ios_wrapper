cdef extern from "Noke_Wrapper_imp.h":
    ctypedef void (*tokenfunc)(const char *name, void *user_data)
    ctypedef char (*clientToken)(const char *session, const char *mac, void *util)
    void request_Unlock(char* macChar, tokenfunc callback, void *user_data)

def requestUnlock(util,mac):

    cdef char macChar = mac.encode('utf-8')

    request_Unlock(macChar, callback, reqTokenFunc, <void*>util)

cdef void callback(const char *name, void *util):
    (<object> util).NokeCallback = (name.decode('utf-8'))

cdef char* reqTokenFunc(const char *session, const char *mac, void *util):
    rsp = (<object> util).sendNokeMessage(session.decode('utf-8'),mac.decode('utf-8'))
    if rsp:
        cdef char* rsp_char = rsp.encode('utf-8')
        return rsp_char