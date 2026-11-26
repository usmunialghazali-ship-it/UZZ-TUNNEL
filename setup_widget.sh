#!/bin/bash
set -e
MANIFEST="android/app/src/main/AndroidManifest.xml"
RES="android/app/src/main/res"
mkdir -p $RES/layout $RES/xml
cat > $RES/layout/widget_layout.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:background="#1A1A2E"
    android:padding="12dp">
    <TextView android:id="@+id/widget_title"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="UZZ TUNNEL"
        android:textColor="#FFFFFF"
        android:textStyle="bold"
        android:textSize="16sp" />
    <TextView android:id="@+id/widget_status"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Disconnected"
        android:textColor="#FFAAAAAA"
        android:textSize="14sp" />
</LinearLayout>
XML
cat > $RES/xml/widget_info.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<appwidget-provider xmlns:android="http://schemas.android.com/apk/res/android"
    android:minWidth="180dp"
    android:minHeight="110dp"
    android:updatePeriodMillis="0"
    android:initialLayout="@layout/widget_layout"
    android:resizeMode="horizontal|vertical"
    android:widgetCategory="home_screen" />
XML
if ! grep -q "UzzWidgetProvider" $MANIFEST; then
python3 - <<'PY'
import pathlib
p = pathlib.Path("android/app/src/main/AndroidManifest.xml")
t = p.read_text()
receiver = '''<receiver android:name=".UzzWidgetProvider" android:exported="false">
            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE" /></intent-filter>
            <meta-data android:name="android.appwidget.provider" android:resource="@xml/widget_info" />
        </receiver>'''
t = t.replace("</application>", receiver + "\n    </application>")
p.write_text(t)
PY
fi
mkdir -p android/app/src/main/kotlin/com/example/uzz_tunnel
cat > android/app/src/main/kotlin/com/example/uzz_tunnel/UzzWidgetProvider.kt <<'KT'
package com.example.uzz_tunnel
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
class UzzWidgetProvider : AppWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
    for (id in appWidgetIds) {
      val widgetData = HomeWidgetPlugin.getData(context)
      val views = RemoteViews(context.packageName, R.layout.widget_layout)
      views.setTextViewText(R.id.widget_status, widgetData.getString("status", "Disconnected"))
      appWidgetManager.updateAppWidget(id, views)
    }
  }
}
KT
echo "widget setup done"
