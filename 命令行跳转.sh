https://stackoverflow.com/questions/11753000/how-to-open-the-google-play-store-directly-from-my-android-application
adb shell am start -a android.intent.action.VIEW -d 'market://details?id=com.miui.systemAdSolution'
