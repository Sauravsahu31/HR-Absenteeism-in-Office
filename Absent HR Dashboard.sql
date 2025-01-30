1. Healthy Bonus Program 
-- Calculate average absenteeism once for reuse
DECLARE @AvgAbsenteeism FLOAT;
SELECT @AvgAbsenteeism = AVG(Absenteeism_time_in_hours) 
FROM Absenteeism_at_work;

-- Retrieve bonus-eligible employees using computed average
SELECT 
    a.ID,
    a.Age,
    a.Body_mass_index AS BMI,
    a.Absenteeism_time_in_hours,
    r.Reason
FROM Absenteeism_at_work a
LEFT JOIN Reasons r 
    ON a.Reason_for_absence = r.Number
WHERE 
    Social_drinker = 0 
    AND Social_smoker = 0
    AND Body_mass_index < 25 
    AND Absenteeism_time_in_hours < @AvgAbsenteeism;


2. Wage Increase for Non-Smokers
-- Calculate total hours worked by non-smokers
WITH NonSmokerHours AS (
    SELECT 
        SUM(Work_load_Average_day * 365) AS Total_Hours 
    FROM Absenteeism_at_work
    WHERE Social_smoker = 0
)

-- Compute hourly rate from budget
SELECT 
    COUNT(*) AS Total_NonSmokers,
    Total_Hours,
    ROUND(983221.21 / Total_Hours, 2) AS Hourly_Increase,
    ROUND((983221.21 / Total_Hours) * 2080, 2) AS Annual_Increase
FROM NonSmokerHours
CROSS JOIN Absenteeism_at_work
WHERE Social_smoker = 0
GROUP BY Total_Hours;


3. Final Query with BMI/Season Categorization 
WITH EmployeeData AS (
    SELECT
        a.ID,
        r.Reason,
        a.Month_of_absence,
        a.Body_mass_index,
        CASE 
            WHEN Body_mass_index < 18.5 THEN 'Underweight'
            WHEN Body_mass_index BETWEEN 18.5 AND 24.9 THEN 'Healthy'
            WHEN Body_mass_index BETWEEN 25 AND 29.9 THEN 'Overweight'
            WHEN Body_mass_index >= 30 THEN 'Obese'
            ELSE 'Unknown' 
        END AS BMI_Category,
        CASE 
            WHEN Month_of_absence IN (12,1,2) THEN 'Winter'
            WHEN Month_of_absence IN (3,4,5) THEN 'Spring'
            WHEN Month_of_absence IN (6,7,8) THEN 'Summer'
            WHEN Month_of_absence IN (9,10,11) THEN 'Fall'
            ELSE 'Unknown' 
        END AS Season,
        a.Transportation_expense,
        a.Absenteeism_time_in_hours
    FROM Absenteeism_at_work a
    LEFT JOIN Reasons r 
        ON a.Reason_for_absence = r.Number
)

SELECT 
    ID,
    Reason,
    BMI_Category,
    Season,
    Transportation_expense,
    Absenteeism_time_in_hours
FROM EmployeeData
ORDER BY Absenteeism_time_in_hours DESC;


Suggested Indexes (Add to Database): These indexes will significantly speed up filtering on smoker/drinker status, BMI, and monthly analysis.
CREATE INDEX idx_smoker ON Absenteeism_at_work (Social_smoker);
CREATE INDEX idx_drinker ON Absenteeism_at_work (Social_drinker);
CREATE INDEX idx_bmi ON Absenteeism_at_work (Body_mass_index);
CREATE INDEX idx_month ON Absenteeism_at_work (Month_of_absence);