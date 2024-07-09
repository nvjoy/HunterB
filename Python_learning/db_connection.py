import tkinter as tk
import ibm_db

def test_db2_connection():
    # Retrieve the input values from the GUI
    hostname = hostname_entry.get()
    port = port_entry.get()
    database = database_entry.get()
    username = username_entry.get()
    password = password_entry.get()

    # Construct the DB2 connection string
    conn_str = f"DATABASE={database};HOSTNAME={hostname};PORT={port};PROTOCOL=TCPIP;UID={username};PWD={password};"

    try:
        # Attempt to establish a connection
        conn = ibm_db.connect(conn_str, "", "")
        result_label.config(text="Connection Successful!", fg="green")
        ibm_db.close(conn)
    except Exception as e:
        result_label.config(text=f"Connection Failed: {str(e)}", fg="red")

# Create the main application window
app = tk.Tk()
app.title("DB2 Connection Test")

# Create and configure labels and entry fields
hostname_label = tk.Label(app, text="Hostname:")
hostname_label.pack()
hostname_entry = tk.Entry(app)
hostname_entry.pack()

port_label = tk.Label(app, text="Port:")
port_label.pack()
port_entry = tk.Entry(app)
port_entry.pack()

database_label = tk.Label(app, text="Database:")
database_label.pack()
database_entry = tk.Entry(app)
database_entry.pack()

username_label = tk.Label(app, text="Username:")
username_label.pack()
username_entry = tk.Entry(app)
username_entry.pack()

password_label = tk.Label(app, text="Password:")
password_label.pack()
password_entry = tk.Entry(app, show="*")  # Mask the password
password_entry.pack()

test_button = tk.Button(app, text="Test Connection", command=test_db2_connection)
test_button.pack()

result_label = tk.Label(app, text="", fg="black")
result_label.pack()

# Start the main event loop
app.mainloop()