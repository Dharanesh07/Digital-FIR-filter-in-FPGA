import matplotlib.pyplot as plt

# Read data from file
with open('input_sig', 'r') as file:
    data = [float(line.strip()) for line in file if line.strip()]

# Create plot
plt.figure(figsize=(12, 6))
plt.plot(data, linewidth=1)
plt.title('Numeric Data Plot')
plt.xlabel('Index')
plt.ylabel('Value')
plt.grid(True, linestyle='--', alpha=0.7)

# Adjust layout to prevent label cutoff
plt.tight_layout()

# Show plot
plt.show()