---
title: Working with the Composer
---

The `ComposerVC` is the component responsible to create new messages or change existing messages. The composer belongs to the `ChatVC` component that integrates the message list and the composer in one view. But if you are not using our `ChatVC` you can use the composer component in isolation with your own chat view as well. The `ComposerVC` manages all the logic and actions of the `ComposerView`, where the latter is only responsible for the composer's layout.

## Customizing the Composer UI
By subclassing the `ComposerView` you can customize the layout of the Composer, for example, changing the position of the views, removing views or adding new ones. Since all the logic of the composer lives on the `ComposerVC`, this is the class to override in case the customization depends on data. Here is an example of customizing the composer to look like the iMessage app:
```swift
final class iMessageComposerView: ComposerView {
    override func setUpLayout() {
        super.setUpLayout()

        leadingContainer.removeArrangedSubview(commandsButton)
        trailingContainer.removeArrangedSubview(sendButton)
        inputMessageView.inputTextContainer.addArrangedSubview(sendButton)
    }
    
    override func setUpAppearance() {
        super.setUpAppearance()

        attachmentButton.setImage(
            UIImage(systemName: "camera.fill"),
            for: .normal
        )
    }
}

final class iMessageComposerVC: ComposerVC {
    override func updateContent() {
        super.updateContent()

        switch content.state {
        case .new:
            composerView.inputMessageView.textView.placeholderLabel.text = "iMessage"
        default:
            break
        }
    }
}

// Then, replace the components:
components.messageComposerVC = iMessageComposerVC.self
components.messageComposerView = iMessageComposerView.self
```

**Result:**
<img src={require("../assets/composer-ui-custom-layout.png").default} width="50%"/>

Since the Composer is built with multiple `ContainerStackView`'s with a similar API of a `UIStackView`, it is very easy to change the Composer layout it is just a question of removing views from containers and adding them back to the desired containers. In this case, we override the `setUpLayout()` lifecycle to remove the `commandsButton` all together and we move the `sendButton` from the `trailingContainer` to the `inputTextContainer`. As a last touch, we change the `attachmentButton` image by overriding the `setUpAppearance()` lifecycle.

## Customizing the Composer Actions
All the actions triggered by the Composer buttons are wired in the `ComposerVC.setUp()` lifecycle. When adding new buttons it is possible to add new actions by overriding this function. Let's imagine an example where we have added a new custom emoji button to open an emoji picker:
```swift
final class CustomComposerVC: ComposerVC {
    override func setUp() {
        super.setUp()

        composerView.emojiButton.addTarget(self, action: #selector(showEmojiPicker), for: .touchUpInside)
    }

    @objc open func showEmojiPicker(sender: UIButton) {
        // Custom implementation of opening the emoji picker
    }
}

components.messageComposerVC = CustomComposerVC.self
```

Besides adding new actions, it is also possible to customize the existing actions, for example, an application might want to present the attachments picker on a completely different view and with different logic:
```swift
final class CustomComposerVC: ComposerVC {
    override func showAttachmentsPicker(sender: UIButton) {
        // Custom implementation of opening the attachments picker
    }
}

components.messageComposerVC = CustomComposerVC.self
```

## Customizing Typing Suggestions
When typing on the composer, if you type `@` it will present a view suggesting users that you can mention, or if you type `/` as the first character, it will show command suggestions. You can customize not only the view of the suggestions but also the logic around it.

### Changing the Recognized Symbol
If your app has a different character to recognize user mentions or commands, then you just need to override the symbols like this:
```swift
final class CustomComposerVC: ComposerVC {
    override var mentionSymbol: String { "👤" }

    override var commandSymbol: String { "⚡️" }
}

components.messageComposerVC = CustomComposerVC.self
```
That's it, with this in place, the suggestions will now be triggered when you type your custom symbol.

### Customizing the Suggestions UI
The UI SDK provides a `ChatSuggestionsVC` component responsible for showing user suggestions and commands suggestions.

#### Basic Customization
In case you only want to change the styling of the container that shows both suggestions, you can override the `ChatSuggestionsVC`. Here is an example of a basic customization of the container component:
```swift
final class CustomChatSuggestionsVC: ChatSuggestionsVC {
    override func setUpAppearance() {
        super.setUpAppearance()

        collectionView.layer.borderWidth = 1
        collectionView.layer.borderColor = appearance.colorPalette.border.cgColor
        collectionView.layer.cornerRadius = 10
        view.layer.shadowOpacity = 0.0
    }
}

components.suggestionsVC = CustomChatSuggestionsVC.self
```
Here we simply remove the shadow and customize the border style of the suggestions component.

**Result:**

| Before  | After |
| ------------- | ------------- |
| <img src={require("../assets/composer-suggestionsVC-before.png").default} width="100%"/> | <img src={require("../assets/composer-suggestionsVC-after.png").default} width="100%"/> |

If you want more customizability and want to change the cells of the suggestions and how the data is formatted, the recommended way is to subclass the `ChatMentionSuggestionView` and `ChatCommandSuggestionView` components.
<!--
#### Example customization of the `ChatMentionSuggestionView`:
TODO

#### Example customization of the `ChatCommandSuggestionsView`:
TODO
--->

#### Advanced Customization
Finally, if you need to have complete control over how the suggestions are presented and not use our `ChatSuggestionsVC` component you can by overriding the following functions:
```swift
final class CustomComposerVC: ComposerVC {
    override func showMentionSuggestions(for typingMention: String, mentionRange: NSRange) {
        // Add your custom implementation to show mention suggestions
    }

    override func showCommandSuggestions(for typingCommand: String) {
        // Add your custom implementation to show command suggestions
    }
}

components.messageComposerVC = CustomComposerVC.self
```

<!--
### Adding New Types of Suggestions
TODO (A good example is recognizing emojis, just like slack/discord.)
--->

### Disabling the Suggestions
Your app might not want to support suggestions at all like the iMessage app, or want to support only one of the suggestions available. You can disable the suggestions feature by just returning `nil` on the following functions:
```swift
final class iMessageComposerVC: ComposerVC {
    override func typingMention(in textView: UITextView) -> (String, NSRange)? {
        // Don't show user suggestions
        return nil
    }

    override func typingCommand(in textView: UITextView) -> String? {
        // Don't show command suggestions
        return nil
    }
}

components.messageComposerVC = iMessageComposerVC.self
```

## Adding a new Composer State

The `ComposerVC` has by default three different states, `.new`, `.edit` and `.quote`, which are represented by the `ComposerState`. These states define if the composer is creating a new message, editing a new message, or quoting an existing message.

| `.new`  | `.edit` | `.quote` |
| ------------- | ------------- | ------------- |
| <img src={require("../assets/composer-ui-state-new.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-edit.png").default} width="100%"/> | <img src={require("../assets/composer-ui-state-quote.png").default} width="100%"/> |

The `ComposerState` is not enum on purpose so it does not cause breaking changes when adding new states and also it provides the possibility to be extendable by you. You can create a new state by creating an extension:

```swift
extension ComposerState {
  public static var custom = ComposerState(rawValue: "custom")
}
```
Then, you can extend `ComposerVC.Content` to support this new state:
```swift
extension ComposerVC.Content {
    public mutating func customState() {
        self = .init(
            text: "",
            state: .custom,
            editingMessage: nil,
            quotingMessage: nil,
            threadMessage: self.threadMessage,
            attachments: self.attachments,
            command: nil
        )
    }
}
```
For better management of the Composer's state and logic, some of the properties are not mutable, including the `state`, `editingMessage` and `quotingMessage` properties. This is to prevent, for example, the composer content to have an invalid state like having an `editingMessage` and `quotingMessage` at the same time. So, to set a new state you need to re-create the composer content, and if you want some of the data to remain the same, just use the current properties for the new content.

Now, with the new state added, not only you can trigger this new state change by calling `content.customState()`, you can also override the `updateContent()` lifecycle in `ComposerVC` to render this new state:
```swift
final class CustomComposerVC: ComposerVC {
    override func updateContent() {
        super.updateContent()

        switch content.state {
        case .custom:
            composerView.titleLabel.text = "Custom State"
        default:
            break
        }
    }
}

components.messageComposerVC = CustomComposerVC.self
```