# Agora RTC engine истифодаи JNI/reflection мекунад — нигоҳ доштани синфҳояш ҳатмист
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# Firebase / Play Services моделҳои JSON-ро бо reflection хонда мешаванд
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
