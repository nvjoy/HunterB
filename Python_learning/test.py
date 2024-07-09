import tkinter as tk

# Create a new Tkinter window
window = tk.Tk()
window.title("DB2 LUW Validation Tool")

# Create a label widget
label = tk.Label(window, text="Hello, There!")
label.pack()

# Create a function to handle button click
def button_click():
    label.config(text="Button Clicked!")

# Create a button widget
button = tk.Button(window, text="Click Me", command=button_click)
button.pack()

# Start the Tkinter event loop
window.mainloop()