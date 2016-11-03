LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)

LUA_JIT_PATH := ../luajit

LOCAL_MODULE := benchmarklib

LOCAL_C_INCLUDES := $(LOCAL_PATH)/$(LUA_JIT_PATH)/src

# Add your application source files here...
LOCAL_SRC_FILES += benchmarklib.c

LOCAL_LDLIBS := -llog -landroid

LOCAL_STATIC_LIBRARIES := libluajit

include $(BUILD_SHARED_LIBRARY)
