package expo.modules.burnt

import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.burnt.overlay.DialogOptions
import expo.modules.burnt.overlay.OverlayCoordinator

class BurntModule : Module() {
  private val coordinator = OverlayCoordinator()

  override fun definition() = ModuleDefinition {
    Name("Burnt")

    AsyncFunction("dialogAsync") { options: DialogOptions, promise: Promise ->
      val activity = appContext.currentActivity
      if (activity == null) {
        promise.resolve(mapOf("status" to "dismissed", "reason" to "lifecycle"))
      } else {
        activity.runOnUiThread { coordinator.enqueue(activity, options, promise) }
      }
    }

    AsyncFunction("dismissAllDialogsAsync") { promise: Promise ->
      val activity = appContext.currentActivity
      if (activity == null) {
        coordinator.dismissAll()
        promise.resolve(null)
      } else {
        activity.runOnUiThread {
          coordinator.dismissAll()
          promise.resolve(null)
        }
      }
    }
  }
}
