pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Polkit
import qs
import qs.components

PromptWindow {
    id: root

    readonly property AuthFlow flow: agent.flow
    property string failure: ""

    namespace: "omde-polkit"
    shown: flow !== null && !flow.isCompleted
    onDismissed: flow?.cancelAuthenticationRequest()
    onShownChanged: {
        failure = "";
        prompt.input.text = "";
        if (shown)
            prompt.input.forceActiveFocus();
    }

    PolkitAgent {
        id: agent
    }

    Connections {
        target: root.flow
        function onAuthenticationFailed() { root.failure = "wrong password"; }
    }

    PasswordPrompt {
        id: prompt
        width: parent.width
        header: root.flow?.message ?? ""
        glyph: Icons.key
        placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "").toLowerCase()
        echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
        status: root.failure || (root.flow?.supplementaryMessage ?? "")
        error: root.failure.length > 0 || root.flow?.supplementaryIsError === true
        onSubmitted: password => {
            if (!root.flow.isResponseRequired)
                return;
            root.failure = "";
            root.flow.submit(password);
        }
        onCancelled: root.dismissed()
    }
}
