adb root
adb shell settings put global captive_portal_http_url http://google.cn/generate_204
adb shell settings put global captive_portal_https_url https://google.cn/generate_204
#但到底使用HTTP还是HTTPS去发请求呢？从这里可以看出，系统获取设置项 captive_portal_use_https 并在获取不到时候取默认值1，所以默认是HTTPS。


#禁用网络检测
adb shell settings put global captive_portal_detection_enabled 0
