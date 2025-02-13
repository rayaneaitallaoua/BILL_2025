import os
import glob
import matplotlib.pyplot as plt


def parse_vcf(vcf_file):
    """Extract DP and DV values from a VCF file."""
    dp_values = []  # Total depth (DP)
    dv_values = []  # Variant depth (DV)

    with open(vcf_file, 'r') as f:
        for line in f:
            if line.startswith("#"):
                continue  # Skip headers
            columns = line.strip().split("\t")
            format_fields = columns[8].split(":")
            sample_values = columns[9].split(":")

            if "DR" in format_fields and "DV" in format_fields:
                dr_index = format_fields.index("DR")
                dv_index = format_fields.index("DV")

                try:
                    dp = int(sample_values[dr_index]) + int(sample_values[dv_index])
                    dv = int(sample_values[dv_index])
                    dp_values.append(dp)
                    dv_values.append(dv)
                except ValueError:
                    continue  # Skip lines with missing or malformed values

    return dp_values, dv_values


def plot_vcf_data(generation_folder):
    """Generate dot plots for all samples in a generation folder."""
    vcf_files = sorted(glob.glob(os.path.join(generation_folder, "*.vcf*")))
    generation_name = os.path.basename(generation_folder)
    num_samples = len(vcf_files)

    if num_samples == 0:
        print(f"No VCF files found in {generation_folder}, skipping...")
        return

    cols = 3  # Number of columns in the grid
    rows = (num_samples // cols) + (num_samples % cols > 0)  # Compute rows

    fig, axes = plt.subplots(rows, cols, figsize=(15, 5 * rows))
    axes = axes.flatten()  # Flatten to 1D for easy indexing

    for i, vcf_file in enumerate(vcf_files):
        dp_values, dv_values = parse_vcf(vcf_file)
        sample_name = os.path.basename(vcf_file).replace(".vcf.gz", "")

        axes[i].scatter(dp_values, dv_values, alpha=0.5)
        axes[i].set_title(sample_name)
        axes[i].set_xlabel("DP (Total Depth)")
        axes[i].set_ylabel("DV (Variant Depth)")

    # Hide any unused subplots
    for j in range(i + 1, len(axes)):
        fig.delaxes(axes[j])

    plt.tight_layout()
    output_file = f"{generation_name}_dotplots.png"
    plt.savefig(output_file, dpi=300)
    print(f"Saved {output_file}")
    plt.close()


def main():
    """Process all generation folders in vcf_files/."""
    generation_folders = sorted(glob.glob("vcf_files/P*"))

    for folder in generation_folders:
        plot_vcf_data(folder)


if __name__ == "__main__":
    main()