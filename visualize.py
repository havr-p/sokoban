# visualizer.py

import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
from typing import List
import subprocess
import os
from solver import SokobanMap  # Updated import to use SokobanMap


class SokobanVisualizer:
    def __init__(self, master):
        self.master = master
        self.master.title("Sokoban Visualizer")

        # Directories
        self.BASE_DIR = os.path.dirname(os.path.abspath(__file__))
        self.MAPS_DIR = os.path.join(self.BASE_DIR, 'maps')
        self.EXPECTED_DIR = os.path.join(self.BASE_DIR, 'expected')
        self.MAPS_OUT_DIR = os.path.join(self.BASE_DIR, 'maps_out')
        self.DOMAIN_FILE = os.path.join(self.BASE_DIR, "sokoban.lp")
        self.TEST_FILE = os.path.join(self.BASE_DIR, "map_test.py")

        os.makedirs(self.MAPS_OUT_DIR, exist_ok=True)

        # Control Frame
        control_frame = tk.Frame(master)
        control_frame.pack(pady=10)

        # Dropdown for map selection
        tk.Label(control_frame, text="Select Map:").grid(row=0, column=0, padx=5, pady=5)
        self.map_var = tk.StringVar()
        self.map_combobox = ttk.Combobox(control_frame, textvariable=self.map_var, state="readonly")
        self.map_combobox['values'] = self.get_map_files()
        self.map_combobox.grid(row=0, column=1, padx=5, pady=5)
        if self.map_combobox['values']:
            self.map_combobox.current(0)

        # Run Test Button
        self.run_button = tk.Button(control_frame, text="Run Test", command=self.run_test, width=10)
        self.run_button.grid(row=0, column=2, padx=5, pady=5)

        # Tabs
        self.notebook = ttk.Notebook(master)
        self.notebook.pack(expand=True, fill='both')

        # Visualization Tab
        self.visual_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.visual_tab, text="Visualization")

        # ASP Map Tab
        self.asp_map_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.asp_map_tab, text="Generated ASP Map")

        # Pytest Output Tab
        self.pytest_output_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.pytest_output_tab, text="Pytest Output")

        # Canvas for Visualization
        self.cell_size = 50
        self.canvas = tk.Canvas(
            self.visual_tab,
            width=500,
            height=500,
            bg="grey",
        )
        self.canvas.pack(pady=10)

        # Frame for navigation buttons
        nav_frame = tk.Frame(self.visual_tab)
        nav_frame.pack(pady=5)

        # Previous Step Button
        self.prev_button = tk.Button(nav_frame, text="Previous Step", command=self.prev_step, state=tk.DISABLED, width=15)
        self.prev_button.grid(row=0, column=0, padx=5)

        # Next Step Button
        self.next_button = tk.Button(nav_frame, text="Next Step", command=self.next_step, state=tk.DISABLED, width=15)
        self.next_button.grid(row=0, column=1, padx=5)

        # Reset Button
        self.reset_button = tk.Button(nav_frame, text="Reset", command=self.reset, state=tk.DISABLED, width=10)
        self.reset_button.grid(row=0, column=2, padx=5)

        # Text widget for ASP Map
        self.asp_text = scrolledtext.ScrolledText(self.asp_map_tab, wrap=tk.WORD, width=60, height=25)
        self.asp_text.pack(padx=10, pady=10)

        # Text widget for Pytest Output
        self.pytest_text = scrolledtext.ScrolledText(self.pytest_output_tab, wrap=tk.WORD, width=60, height=25)
        self.pytest_text.pack(padx=10, pady=10)

        # Step counter
        self.current_step = 0
        self.solution_steps: List[str] = []
        self.maps: List[str] = []
        self.sokoban_map: SokobanMap = None

    def get_map_files(self) -> List[str]:
        """Retrieve a list of map files from the maps directory."""
        return sorted([
            f for f in os.listdir(self.MAPS_DIR)
            if os.path.isfile(os.path.join(self.MAPS_DIR, f)) and f.endswith('.txt')
        ])

    def run_test(self):
        """Run the pytest for the selected map and update the visualization."""
        selected_map = self.map_var.get()
        if not selected_map:
            messagebox.showwarning("No Map Selected", "Please select a map to run the test.")
            return

        map_path = os.path.join(self.MAPS_DIR, selected_map)
        expected_file = self.get_expected_file(selected_map)
        if not expected_file:
            messagebox.showerror("Expected File Missing", f"No expected file found for {selected_map}.")
            return
        expected_path = os.path.join(self.EXPECTED_DIR, expected_file)

        # Run pytest for the selected map
        try:
            cmd = [
                'pytest',
                self.TEST_FILE,
                '--tb=short',
                '-v',
                '-s',
                f'--map={selected_map}'
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            pytest_output = result.stdout
        except subprocess.CalledProcessError as e:
            pytest_output = e.stdout + "\n" + e.stderr
            messagebox.showerror("Pytest Error", f"An error occurred while running pytest:\n{pytest_output}")

        # Display Pytest Output
        self.pytest_text.delete(1.0, tk.END)
        self.pytest_text.insert(tk.END, pytest_output)

        # Parse Solution Steps from Pytest Output
        self.solution_steps = self.parse_solution_steps(pytest_output)
        if not self.solution_steps:
            messagebox.showinfo("No Solution", "No solution steps found in the pytest output.")
            return

        # Initialize SokobanMap
        try:
            map_str = SokobanMap.read_map_file(map_path)  # Now works correctly
        except Exception as e:
            messagebox.showerror("Map Read Error", f"An error occurred while reading the map file:\n{e}")
            return

        self.sokoban_map = SokobanMap(map_str)

        # Gather map steps using the new method
        try:
            self.maps = self.sokoban_map.get_map_steps(self.solution_steps)
        except Exception as e:
            messagebox.showerror("Map Steps Error", f"An error occurred while gathering map steps:\n{e}")
            return

        self.current_step = 0

        # Display Generated ASP Map
        generated_map_path = os.path.join(self.MAPS_OUT_DIR, f"generated_{selected_map}")
        try:
            #SokobanMap.write_map_file(generated_map_path, self.maps[-1])  # Now works correctly
            self.display_generated_asp_map(generated_map_path)
        except Exception as e:
            messagebox.showerror("ASP Map Write Error", f"An error occurred while writing the generated ASP map:\n{e}")

        # Render the initial map
        self.render_map(self.maps[self.current_step])

        # Enable navigation buttons if there are steps to navigate
        if len(self.maps) > 1:
            self.next_button.config(state=tk.NORMAL)
            self.reset_button.config(state=tk.NORMAL)
            # Disable Previous button initially
            self.prev_button.config(state=tk.DISABLED)

        messagebox.showinfo("Test Completed", f"Test for {selected_map} completed successfully.")

    def get_expected_file(self, map_file: str) -> str:
        """Get the corresponding expected file for a given map file."""
        base_name = os.path.splitext(map_file)[0]
        expected_file = f"expected{base_name[-1]}.txt"  # Assumes naming like map4.txt -> expected4.txt
        if os.path.exists(os.path.join(self.EXPECTED_DIR, expected_file)):
            return expected_file
        return ""

    def parse_solution_steps(self, pytest_output: str) -> List[str]:
        """Extract solution steps from pytest output."""
        steps = []
        for line in pytest_output.splitlines():
            if line.startswith("Step"):
                parts = line.split(": ", 1)
                if len(parts) == 2:
                    steps.append(parts[1])
        return steps

    def display_generated_asp_map(self, asp_map_path: str):
        """Display the generated ASP map in the ASP Map tab."""
        try:
            with open(asp_map_path, 'r', encoding='utf-8') as file:
                asp_map = file.read()
            self.asp_text.delete(1.0, tk.END)
            self.asp_text.insert(tk.END, asp_map)
        except FileNotFoundError:
            self.asp_text.delete(1.0, tk.END)
            self.asp_text.insert(tk.END, f"Generated ASP map file not found: {asp_map_path}")
        except Exception as e:
            self.asp_text.delete(1.0, tk.END)
            self.asp_text.insert(tk.END, f"Error reading ASP map file: {e}")

    def render_map(self, map_str: str):
        """Render the given map string onto the Tkinter Canvas."""
        self.canvas.delete("all")
        lines = map_str.splitlines()

        # Update canvas size based on map dimensions
        self.map_height = len(lines)
        self.map_width = max(len(line) for line in lines) if lines else 0
        self.canvas.config(
            width=self.map_width * self.cell_size,
            height=self.map_height * self.cell_size
        )

        # Draw grid and background
        for r in range(self.map_height):
            for c in range(self.map_width):
                x1, y1 = c * self.cell_size, r * self.cell_size
                x2, y2 = x1 + self.cell_size, y1 + self.cell_size
                self.canvas.create_rectangle(x1, y1, x2, y2, outline="gray", fill="white")

        # Draw map elements
        for r, row in enumerate(lines):
            for c, cell in enumerate(row):
                x1, y1 = c * self.cell_size, r * self.cell_size
                x2, y2 = x1 + self.cell_size, y1 + self.cell_size

                if cell == "#":  # Wall
                    self.canvas.create_rectangle(x1, y1, x2, y2, fill="gray20")
                    self.canvas.create_text(
                        (x1 + x2) // 2,
                        (y1 + y2) // 2,
                        text="#",
                        font=("Arial", 16),
                        fill="white"
                    )
                elif cell in ("X", "s", "c"):  # Goal or Sokoban/Crate on goal
                    self.canvas.create_rectangle(x1, y1, x2, y2, fill="lightgreen")
                    self.canvas.create_text(
                        (x1 + x2) // 2,
                        (y1 + y2) // 2,
                        text="X",
                        font=("Arial", 16),
                        fill="red",
                    )

                # Draw Sokoban
                if cell in ("S", "s"):
                    self.canvas.create_oval(
                        x1 + 10, y1 + 10, x2 - 10, y2 - 10, fill="blue"
                    )
                    self.canvas.create_text(
                        (x1 + x2) // 2,
                        (y1 + y2) // 2,
                        text=cell,  # "S" or "s"
                        font=("Arial", 16),
                        fill="white"
                    )

                # Draw Crate
                if cell in ("C", "c"):
                    self.canvas.create_rectangle(
                        x1 + 8, y1 + 8, x2 - 8, y2 - 8,
                        fill="orange", outline="black"
                    )
                    self.canvas.create_text(
                        (x1 + x2) // 2,
                        (y1 + y2) // 2,
                        text=cell,  # "C" or "c"
                        font=("Arial", 16),
                        fill="white"
                    )

    def next_step(self):
        """Go to the next step and render the map."""
        if self.current_step < len(self.maps) - 1:
            self.current_step += 1
            self.render_map(self.maps[self.current_step])

            # Enable Previous button if not at the first step
            if self.current_step > 0:
                self.prev_button.config(state=tk.NORMAL)

            # Disable Next button if at the last step
            if self.current_step == len(self.maps) - 1:
                self.next_button.config(state=tk.DISABLED)

    def prev_step(self):
        """Go to the previous step and render the map."""
        if self.current_step > 0:
            self.current_step -= 1
            self.render_map(self.maps[self.current_step])

            # Enable Next button if not at the last step
            if self.current_step < len(self.maps) - 1:
                self.next_button.config(state=tk.NORMAL)

            # Disable Previous button if at the first step
            if self.current_step == 0:
                self.prev_button.config(state=tk.DISABLED)

    def reset(self):
        """Reset the visualization to the initial state."""
        self.current_step = 0
        self.render_map(self.maps[self.current_step])

        # Disable Previous button as we're at the first step
        self.prev_button.config(state=tk.DISABLED)

        # Enable Next button if there are steps to navigate
        if len(self.maps) > 1:
            self.next_button.config(state=tk.NORMAL)
        else:
            self.next_button.config(state=tk.DISABLED)


def visualize_solution():
    """Create a Tkinter window to visualize the solution."""
    root = tk.Tk()
    app = SokobanVisualizer(root)
    root.mainloop()


if __name__ == "__main__":
    visualize_solution()
