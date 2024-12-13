import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from ruptures import Binseg
from sklearn.linear_model import LinearRegression

# Streamlit App
st.title("Structural Break Analysis")

# File upload section
uploaded_file = st.file_uploader("Upload your dataset (CSV, Excel, etc.):", type=["csv", "xlsx"])
if uploaded_file is not None:
    # Read the uploaded file
    if uploaded_file.name.endswith(".csv"):
        data = pd.read_csv(uploaded_file)
    else:
        data = pd.read_excel(uploaded_file)

    # Display the dataset
    st.write("Dataset Preview:", data.head())

    # Select column for analysis
    column = st.selectbox("Select the column for Structural Break Analysis:", options=data.columns)

    # Input start and end years
    start_year = st.number_input("Enter start year:", min_value=1900, max_value=2100, value=1995, step=1)
    end_year = st.number_input("Enter end year:", min_value=1900, max_value=2100, value=2022, step=1)

    # Ensure valid time range
    if start_year >= end_year:
        st.error("Start year must be less than end year.")
    else:
        time = np.arange(start_year, end_year + 1)

        # Ensure column is numeric
        data[column] = pd.to_numeric(data[column], errors='coerce')
        data = data.dropna(subset=[column])

        # Perform Bai-Perron structural break analysis
        model = Binseg(model="l2")
        model.fit(data[column].values)

        # Identify breakpoints
        n_bkps = st.slider("Select number of breakpoints to detect:", min_value=1, max_value=10, value=4)
        breakpoints = model.predict(n_bkps=n_bkps)

        st.write("Breakpoints at observation indices:", breakpoints)

        # Plot the data with breakpoints
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.plot(time[:len(data[column])], data[column], label=f"{column}", color="blue")

        for bp in breakpoints[:-1]:  # Exclude the final breakpoint (end of data)
            ax.axvline(x=time[bp - 1], color="red", linestyle="--", label="Breakpoint")

        ax.set_title("Structural Break Analysis")
        ax.set_xlabel("Year")
        ax.set_ylabel(column)
        ax.legend(loc="best")
        ax.grid()
        st.pyplot(fig)

        # Perform segmented regression
        segments = []
        regression_lines = []

        for i, bp in enumerate([0] + breakpoints):
            start = bp if i != 0 else 0
            end = breakpoints[i] if i < len(breakpoints) - 1 else len(data[column])

            X = np.arange(start_year, start_year + (end - start)).reshape(-1, 1)
            y = data[column].iloc[start:end]

            reg_model = LinearRegression()
            reg_model.fit(X, y)

            regression_lines.append((X, reg_model.predict(X)))
            segments.append((start, end))

        # Plot segmented regression
        fig, ax = plt.subplots(figsize=(10, 6))
        ax.plot(time[:len(data[column])], data[column], label=f"{column}", color="blue")

        for bp in breakpoints[:-1]:
            ax.axvline(x=time[bp - 1], color="red", linestyle="--")

        for X, y_pred in regression_lines:
            ax.plot(X, y_pred, color="green", label="Segmented Regression")

        ax.set_title("Segmented Regression with Breakpoints")
        ax.set_xlabel("Year")
        ax.set_ylabel(column)
        ax.legend(loc="best")
        ax.grid()
        st.pyplot(fig)

        # Results table
        results = []
        for i, (start, end) in enumerate(segments):
            segment_data = data[column].iloc[start:end]
            results.append({
                "Segment": i + 1,
                "Start Year": start_year + start,
                "End Year": start_year + end - 1,
                "Mean": segment_data.mean(),
                "Std Dev": segment_data.std()
            })

        results_df = pd.DataFrame(results)
        st.write("Analysis Results:")
        st.dataframe(results_df)

        # Interpretation
        st.subheader("Interpretation")
        st.write("The structural break analysis reveals significant changes in the trend of the selected column. Each segment represents a stable period, and the identified breakpoints indicate points of abrupt change.")
