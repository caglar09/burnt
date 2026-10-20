package expo.modules.burnt.overlay

import android.app.Activity
import android.app.Application
import android.app.Dialog
import android.os.Bundle
import expo.modules.kotlin.Promise
import java.lang.ref.WeakReference

// All public methods must be called on the Android UI thread.
class OverlayCoordinator : Application.ActivityLifecycleCallbacks {
  private class Request(val options: DialogOptions, val promise: Promise) {
    var settled = false
    fun resolve(result: Map<String, Any>) {
      if (settled) return
      settled = true
      promise.resolve(result)
    }
  }
  private var current: Request? = null
  private val queue = ArrayDeque<Request>()
  private var dialog: Dialog? = null
  private var host = WeakReference<Activity>(null)
  private var registeredApplication: Application? = null

  fun enqueue(activity: Activity, options: DialogOptions, promise: Promise) {
    if (activity.isFinishing || activity.isDestroyed) {
      promise.resolve(mapOf("status" to "dismissed", "reason" to "lifecycle"))
      return
    }
    host = WeakReference(activity)
    if (registeredApplication == null) {
      val app = activity.application
      app.registerActivityLifecycleCallbacks(this)
      registeredApplication = app
    }
    val request = Request(options, promise)
    if (current != null) {
      when (options.queuePolicy) {
        DialogPolicy.reject -> {
          promise.reject("ERR_DIALOG_ACTIVE", "A dialog is already displayed.", null)
          return
        }
        DialogPolicy.replace -> {
          clearCurrent("programmatic")
          queue.addFirst(request)
        }
        DialogPolicy.enqueue -> queue.addLast(request)
      }
    } else queue.addLast(request)
    showNext()
  }

  fun dismissAll(reason: String = "programmatic") {
    val queued = queue.toList()
    queue.clear()
    clearCurrent(reason)
    queued.forEach { it.resolve(mapOf("status" to "dismissed", "reason" to reason)) }
    cleanupIfIdle()
  }

  private fun clearCurrent(reason: String) {
    val request = current
    current = null
    dialog?.setOnCancelListener(null)
    dialog?.dismiss()
    dialog = null
    request?.resolve(mapOf("status" to "dismissed", "reason" to reason))
  }

  private fun showNext() {
    if (current != null) return
    val activity = host.get()
    if (activity == null || activity.isFinishing || activity.isDestroyed) {
      dismissAll("lifecycle")
      return
    }
    val request = queue.removeFirstOrNull() ?: run {
      cleanupIfIdle()
      return
    }
    current = request
    try {
      dialog = NativeDialog(activity, request.options,
        onAction = { actionId, values ->
          if (current !== request) return@NativeDialog
          request.resolve(mapOf("status" to "action", "actionId" to actionId, "values" to values))
          current = null
          dialog?.dismiss()
          dialog = null
          showNext()
        },
        onDismiss = { reason ->
          if (current !== request) return@NativeDialog
          request.resolve(mapOf("status" to "dismissed", "reason" to reason))
          current = null
          dialog?.dismiss()
          dialog = null
          showNext()
        }
      ).show()
    } catch (e: Exception) {
      current = null
      request.resolve(mapOf("status" to "dismissed", "reason" to "lifecycle"))
      showNext()
    }
  }

  private fun cleanupIfIdle() {
    if (current == null && queue.isEmpty()) {
      registeredApplication?.unregisterActivityLifecycleCallbacks(this)
      registeredApplication = null
      host.clear()
    }
  }

  override fun onActivityDestroyed(activity: Activity) {
    if (host.get() === activity) dismissAll("lifecycle")
  }
  override fun onActivityStopped(activity: Activity) {
    if (host.get() === activity && !activity.isChangingConfigurations) {
      dismissAll("lifecycle")
    }
  }
  override fun onActivityCreated(activity: Activity, state: Bundle?) {}
  override fun onActivityStarted(activity: Activity) {}
  override fun onActivityResumed(activity: Activity) {}
  override fun onActivityPaused(activity: Activity) {}
  override fun onActivitySaveInstanceState(activity: Activity, state: Bundle) {}
}
