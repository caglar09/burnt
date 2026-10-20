package expo.modules.burnt.overlay

import android.app.Activity
import android.app.Dialog
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.InputFilter
import android.text.InputType
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

// The Dialog owns an application window above the Activity's RN Modal Dialog window.
class NativeDialog(
  private val activity: Activity,
  private val options: DialogOptions,
  private val onAction: (String, Map<String, String>) -> Unit,
  private val onDismiss: (String) -> Unit
) {
  private val night = (activity.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
    Configuration.UI_MODE_NIGHT_YES
  private val foregroundColor = if (night) Color.WHITE else Color.rgb(25, 25, 28)
  private val backgroundColor = if (night) Color.rgb(37, 37, 40) else Color.WHITE
  private val secondaryColor = if (night) Color.rgb(55, 55, 60) else Color.rgb(240, 240, 243)
  private val fields = mutableMapOf<String, EditText>()
  private var finished = false

  private fun dp(v: Int) = (v * activity.resources.displayMetrics.density + 0.5f).toInt()
  private fun shape(color: Int, stroke: Int? = null) = GradientDrawable().apply {
    setColor(color)
    cornerRadius = dp(11).toFloat()
    if (stroke != null) setStroke(dp(1), stroke)
  }
  private fun label(text: String, size: Float, bold: Boolean = false): TextView =
    TextView(activity).apply {
      this.text = text
      textSize = size
      setTextColor(foregroundColor)
      gravity = Gravity.CENTER
      if (bold) setTypeface(null, Typeface.BOLD)
    }

  fun show(): Dialog {
    val dialog = Dialog(activity)
    val box = LinearLayout(activity).apply {
      orientation = LinearLayout.VERTICAL
      setPadding(dp(22), dp(22), dp(22), dp(20))
      background = shape(backgroundColor)
    }
    fun append(view: View, marginBottom: Int = 14) {
      val params = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
      )
      params.bottomMargin = dp(marginBottom)
      box.addView(view, params)
    }

    if (options.icon != DialogIcon.none) {
      val symbol = when (options.icon) {
        DialogIcon.info -> "ⓘ"
        DialogIcon.success -> "✓"
        DialogIcon.warning -> "⚠"
        DialogIcon.error -> "✕"
        else -> ""
      }
      append(label(symbol, 36f, true).apply {
        setTextColor(if (options.icon == DialogIcon.warning ||
          options.icon == DialogIcon.error) Color.rgb(237, 56, 64) else Color.rgb(32, 104, 246))
      }, 8)
    }

    append(label(options.title, 21f, true), 11)
    options.message?.takeIf { it.isNotEmpty() }?.let {
      append(label(it, 15f).apply { alpha = 0.8f }, 20)
    }

    for (field in options.fields) {
      val input = EditText(activity).apply {
        setText(field.value)
        hint = field.placeholder
        textSize = 16f
        setTextColor(foregroundColor)
        setHintTextColor(if (night) Color.LTGRAY else Color.GRAY)
        background = shape(secondaryColor)
        setPadding(dp(12), dp(11), dp(12), dp(11))
        if (field.type == DialogFieldType.textarea) {
          inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_MULTI_LINE or
            InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
          minLines = 3
          maxLines = 6
          gravity = Gravity.TOP or Gravity.START
        } else {
          inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
          isSingleLine = true
        }
        field.maxLength?.takeIf { it > 0 }?.let {
          filters = arrayOf(InputFilter.LengthFilter(it))
        }
      }
      fields[field.id] = input
      append(input, 12)
    }

    val error = label("Please complete all required fields.", 13f).apply {
      setTextColor(Color.rgb(237, 56, 64))
      visibility = View.GONE
    }
    append(error, 0)

    val buttons = LinearLayout(activity).apply {
      orientation = if (options.actions.size <= 2) LinearLayout.HORIZONTAL else LinearLayout.VERTICAL
      gravity = Gravity.CENTER
    }
    options.actions.forEachIndexed { index, action ->
      val button = Button(activity).apply {
        text = action.title
        textSize = 15f
        isAllCaps = false
        setTypeface(null, Typeface.BOLD)
        setTextColor(if (action.style == DialogActionStyle.cancel) foregroundColor else Color.WHITE)
        background = shape(when (action.style) {
          DialogActionStyle.cancel -> secondary
          DialogActionStyle.destructive -> Color.rgb(241, 55, 63)
          DialogActionStyle.default -> Color.rgb(28, 99, 237)
        })
        setOnClickListener {
          if (finished) return@setOnClickListener
          val values = fields.mapValues { it.value.text.toString() }
          if (action.style != DialogActionStyle.cancel &&
            options.fields.any { it.required && values[it.id].isNullOrBlank() }) {
            error.visibility = View.VISIBLE
            return@setOnClickListener
          }
          finished = true
          onAction(action.id, values)
        }
      }
      val params = LinearLayout.LayoutParams(
        if (buttons.orientation == LinearLayout.HORIZONTAL) 0 else ViewGroup.LayoutParams.MATCH_PARENT,
        dp(49),
        if (buttons.orientation == LinearLayout.HORIZONTAL) 1f else 0f
      )
      if (index > 0) {
        if (buttons.orientation == LinearLayout.HORIZONTAL) params.marginStart = dp(10)
        else params.topMargin = dp(9)
      }
      buttons.addView(button, params)
    }
    append(buttons, 0)

    val scroll = ScrollView(activity).apply {
      isFillViewport = false
      isVerticalScrollBarEnabled = false
      addView(box)
    }
    dialog.setContentView(scroll)
    dialog.setCancelable(options.dismissOnBack || options.dismissOnBackdrop)
    dialog.setCanceledOnTouchOutside(options.dismissOnBackdrop)
    var backPressed = false
    dialog.setOnKeyListener { _, keyCode, event ->
      if (keyCode == KeyEvent.KEYCODE_BACK) {
        if (event.action == KeyEvent.ACTION_UP && options.dismissOnBack) {
          backPressed = true
          dialog.cancel()
        }
        true
      } else false
    }
    dialog.setOnCancelListener {
      if (!finished) {
        finished = true
        onDismiss(if (backPressed) "back" else "backdrop")
      }
    }
    dialog.show()
    dialog.window?.apply {
      setBackgroundDrawableResource(android.R.color.transparent)
      addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
      setDimAmount(0.5f)
      setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
      val screen = activity.resources.displayMetrics.widthPixels
      setLayout(minOf(screen - dp(32), dp(390)), ViewGroup.LayoutParams.WRAP_CONTENT)
    }
    return dialog
  }
}
