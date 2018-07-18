STUFF = "Hi"

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
    import ast
    from userClient import connectToServer
    msg = ast.literal_eval(
        '{"function":"Noke_Unlock","session":"' + str(session.decode('utf-8')) + '","mac":"' + str(mac.decode('utf-8')) + '"}')
    rsp = connectToServer('206.189.163.242', 8080, msg)
    if rsp['result'] == "success":
        commandStr = rsp['data']["commands"]
    else:
        commandStr = ''
    cdef bytes command_bytes = commandStr.encode('utf-8')
    return commandStr
    #rsp = (<object> util).sendNokeMessage((session.decode('utf-8')),(mac.decode('utf-8')))
    #if rsp:
    #    return rsp.encode('utf-8')