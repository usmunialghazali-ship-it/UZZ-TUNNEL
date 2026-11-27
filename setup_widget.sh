#!/bin/bash
set -e
RES="android/app/src/main/res"
mkdir -p $RES/layout $RES/xml
mkdir -p android/app/src/main/kotlin/com/example/uzz_tunnel

cat > $RES/layout/widget_layout.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="horizontal"
    android:gravity="center_vertical"
    android:padding="12dp"
    android:background="#1A1A2E">
    <ImageView
        android:layout_width="32dp"
        android:layout_height="32dp"
        android:src="@android:drawable/sym_def_app_icon" />
    <LinearLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:orientation="vertical"
        android:layout_marginStart="10dp">
        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="UZZ TUNNEL"
            android:textColor="#FFFFFF"
            android:textStyle="bold"
            android:textSize="13sp" />
        <TextView
            android:layout_width="wrap_content"
            android:layout_height="wrap_content"
            android:text="Terputus"
            android:textColor="#FF3B30"
            android:textSize="11sp" />
    </LinearLayout>
</LinearLayout>
XML

cat > $RES/xml/widget_info.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="110dp"
    android:minHeight="40dp"
    android:targetCellWidth="2"
    android:targetCellHeight="1"
    android:updatePeriodMillis="0"
    android:resizeMode="none"
    android:widgetCategory="home_screen"
    android:initialLayout="@layout/widget_layout"
    android:previewLayout="@layout/widget_layout" />
XML

python3 << 'PY'
import pathlib
p = pathlib.Path("android/app/src/main/AndroidManifest.xml")
t = p.read_text()
receiver = """<receiver android:name=".UzzWidgetProvider" android:exported="false">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/widget_info" />
        </receiver>"""
if "UzzWidgetProvider" not in t:
    t = t.replace("</application>", receiver + "\n    </application>")
    p.write_text(t)
PY

cat > android/app/src/main/kotlin/com/example/uzz_tunnel/UzzWidgetProvider.kt <<'KT'
package com.example.uzz_tunnel
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
class UzzWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
KT
echo "widget setup done"
