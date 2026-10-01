package app.firedom.firedom

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

// W1 홈 위젯 (PRD): D-day + 진행률 + 편차 배지. 금액 표시 금지.
// 데이터는 Dart(syncHomeWidget)가 home_widget prefs로 push한다.
class FiredomWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.firedom_widget).apply {
                setTextViewText(
                    R.id.widget_dday,
                    prefs.getString("dday_text", context.getString(R.string.widget_placeholder))
                )
                setTextViewText(
                    R.id.widget_deviation,
                    prefs.getString("deviation_text", "")
                )
                setProgressBar(R.id.widget_progress, 100, prefs.getInt("progress", 0), false)
            }

            // 탭 → 앱 홈으로
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
