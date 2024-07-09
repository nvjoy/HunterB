import tkinter as tk
from tkinter import ttk

class PlaybookApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Playbook Runner")

        self.playbooks = {
            "Playbook 1": ["Option 1.1", "Option 1.2", "Option 1.3"],
            "Playbook 2": ["Option 2.1", "Option 2.2"],
            "Playbook 3": ["Option 3.1", "Option 3.2", "Option 3.3", "Option 3.4"]
        }

        self.selected_playbook = tk.StringVar()
        self.selected_option = tk.StringVar()

        self.create_widgets()

    def create_widgets(self):
        # Playbook selection dropdown
        playbook_label = tk.Label(self.root, text="Select Playbook:")
        playbook_label.pack(pady=5)
        self.playbook_dropdown = ttk.Combobox(self.root, textvariable=self.selected_playbook, values=list(self.playbooks.keys()))
        self.playbook_dropdown.pack(pady=5)
        self.playbook_dropdown.bind("<<ComboboxSelected>>", self.update_options)

        # Options dropdown
        self.option_label = tk.Label(self.root, text="Select Option:")
        self.option_label.pack(pady=5)
        self.option_dropdown = ttk.Combobox(self.root, textvariable=self.selected_option)
        self.option_dropdown.pack(pady=5)

        # Run button
        run_button = tk.Button(self.root, text="Run", command=self.run_playbook)
        run_button.pack(pady=5)

        # Cancel button
        cancel_button = tk.Button(self.root, text="Cancel", command=self.root.quit)
        cancel_button.pack(pady=5)

    def update_options(self, event):
        selected_playbook = self.selected_playbook.get()
        options = self.playbooks.get(selected_playbook, [])
        self.option_dropdown['values'] = options
        self.selected_option.set('')

    def run_playbook(self):
        selected_playbook = self.selected_playbook.get()
        selected_option = self.selected_option.get()
        print(f"Running {selected_playbook} with {selected_option}")

if __name__ == "__main__":
    root = tk.Tk()
    app = PlaybookApp(root)
    root.mainloop()
