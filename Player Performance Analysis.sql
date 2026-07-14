# 11 July 2026
/*
 PLAYER PERFORMANCE ANALYSIS IN A TOURNAMENT
 
 Business Problem
 A Tournament involves hundreds of players participating across multiple matches and innings. 
 Coaches, selectors, analysts, and team management require an objective, data-driven approach to 
 evaluate player performance instead of relying solely on total runs or wickets.

Traditional scorecards provide match-wise statistics but do not answer strategic questions such as:

Who are the most consistent performers?
Which young players have the highest growth potential?
Which bowlers perform well in pressure situations?
Which batters contribute most to winning matches?
Which players are underperforming despite getting opportunities?

A centralized analytics dashboard is required to transform raw scorecard data 
into actionable insights for player selection and performance evaluation.

Problem Statement

Develop an end-to-end analytics solution using SQL and Power BI to analyze batting and bowling performances across the Ranji Trophy 2025–26 season.

The solution should identify:

Top-performing batters and bowlers
Consistent performers
Emerging future stars
Match-winning contributors
Team-wise strengths and weaknesses
Player trends across the tournament

The system should enable selectors and analysts to make data-driven decisions rather than subjective judgments.

Objectives
Build a structured cricket analytics database.
Analyze batting and bowling performances across all matches.
Identify the best batter and best bowler.
Detect consistent performers.
Identify future star players.
Compare team performances.
Create interactive Power BI dashboards.
Enable player comparison.
Discover hidden performance patterns.
Provide insights for team selection.
*/

CREATE DATABASE tournamentdb;
use tournamentdb;


SHOW TABLES;

ALTER TABLE Players
ADD PRIMARY KEY (PlayerID);

SELECT PlayerID, COUNT(*)
FROM Players
GROUP BY PlayerID
HAVING COUNT(*) > 1;

ALTER TABLE Match_Info
ADD PRIMARY KEY (MatchID);

ALTER TABLE Batting
ADD PRIMARY KEY (BattingID),
ADD CONSTRAINT FK_Batting_Player
FOREIGN KEY (PlayerID)
REFERENCES Players(PlayerID),
ADD CONSTRAINT FK_Batting_Match
FOREIGN KEY (MatchID)
REFERENCES Match_Info(MatchID);

SELECT * FROM MATCH_INFO;

SELECT * FROM PLAYERS;
ALTER TABLE PLAYERS
DROP COLUMN PLAYERNAME;

SELECT * FROM BATTING;
ALTER TABLE BATTING
RENAME COLUMN PLAYERNAME TO PLAYER;

SELECT * FROM BOWLING;
ALTER TABLE BOWLING
DROP COLUMN BOWLERNAME;

SELECT * FROM INNINGS_SUMMARY;

# 1. Total Runs by Player
SELECT player,
SUM(Runs) AS totalRuns
FROM Batting
GROUP BY player
ORDER BY totalRuns DESC;

# 2. Total Wickets by Bowler
SELECT bowler,
SUM(wickets) AS totalWickets
FROM bowling
GROUP BY bowler
ORDER BY totalWickets DESC;

# 2.1 Least Performing Bowler
SELECT Bowler,  Sum(Wickets) Total_Wickets, AVG(Economy) AVG_ECONOMY
FROM bowling
GROUP BY Bowler
HAVING TOTAL_WICKETS>=5
ORDER BY AVG_ECONOMY DESC
LIMIT 10;


# 3. Top 10 Run Scorers
SELECT
Player,
SUM(Runs) AS TotalRuns
FROM Batting
GROUP BY Player
ORDER BY TotalRuns DESC
LIMIT 10;

# 4. Top 10 Wicket Takers
SELECT
Bowler,
SUM(Wickets) AS TotalWickets
FROM Bowling
GROUP BY Bowler
ORDER BY TotalWickets DESC
LIMIT 10;

# 3. BEST AVERAGE
SELECT
player,
SUM(runs) AS runs, COUNT(*) AS innings,
ROUND(SUM(runs)/COUNT(*),2) AS Batting_Average
FROM batting
GROUP BY player HAVING COUNT(*)>=5
ORDER BY Batting_Average DESC LIMIT 10;


# 3.1 LEAST AVERAGE (Players Not Performing Well)
SELECT player,
SUM(runs) AS runs, COUNT(*) AS innings,
ROUND(SUM(runs)/COUNT(*),2) AS Batting_Average
FROM batting
GROUP BY player HAVING COUNT(*)>=5
ORDER BY Batting_Average LIMIT 15;

# HIGHEST STRIKE RATE
SELECT
Player,
ROUND(SUM(Runs)*100.0/SUM(Balls),2) AS StrikeRate
FROM Batting
GROUP BY Player HAVING SUM(Balls)>=150
ORDER BY StrikeRate DESC LIMIT 10;

# 5. Most Consistent Batter
SELECT
player,
COUNT(*) AS Consistent_Innings
FROM batting
WHERE runs>=50 GROUP BY player
ORDER BY Consistent_Innings DESC LIMIT 10; 

# 6. CONSISTENCY RANKING
WITH Consistency AS
( 	SELECT player, COUNT(*) Consistent_Innings
	FROM Batting
	WHERE Runs>=50 GROUP BY Player
)
SELECT Player, Consistent_Innings,
RANK() OVER(ORDER BY Consistent_Innings DESC) PlayerRank
FROM Consistency LIMIT 10; 

# 7. Identify players contributing with both bat and ball.
WITH BattingCTE AS
(	SELECT PlayerID, Player,
	SUM(Runs) Runs
	FROM Batting
	GROUP BY PlayerID,Player),
BowlingCTE AS
(	SELECT PlayerID, Bowler,
	SUM(Wickets) Wickets
	FROM Bowling
	GROUP BY PlayerID,Bowler)
SELECT
b.Player, Runs, Wickets,
Runs+(Wickets*25) AS MVPScore
FROM BattingCTE b
JOIN BowlingCTE bw
ON b.PlayerID=bw.PlayerID
ORDER BY MVPScore DESC;

# 7. Which player contributes the highest percentage of their team's runs?
SELECT
Player,
Team,
PlayerRuns,
TeamRuns,
ROUND((PlayerRuns*100.0)/TeamRuns,2) Contribution
FROM
(
SELECT
Player,
Team,
SUM(Runs) PlayerRuns,
SUM(SUM(Runs)) OVER(PARTITION BY Team) TeamRuns
FROM Batting
GROUP BY Player,Team
)t
ORDER BY Contribution DESC;

#9. Emerging Player
SELECT *
FROM (
	SELECT Player,
	COUNT(*) Matches,
	AVG(Runs) Avg_Runs,
	SUM(Runs) Runs
	FROM Batting
	GROUP BY Player
    ORDER BY Matches DESC
) t
WHERE (Matches<=10 AND Matches >=5) AND Avg_Runs>45;

# 10. Player Ranking
SELECT
Team, Player,
SUM(Runs) AS TotalRuns,
RANK() OVER(
PARTITION BY Team
ORDER BY SUM(Runs) DESC
) AS TeamRank
FROM Batting
GROUP BY Team,Player;

#11. STATS OF BEST BATTER
WITH BestBatter AS
(    SELECT
        Player, SUM(Runs) AS Total_Runs
    FROM Batting
    GROUP BY Player
    ORDER BY Total_Runs DESC LIMIT 1) 
SELECT
    b.Player, COUNT(*) AS Innings, SUM(Runs) AS Total_Runs,
    MAX(Runs) AS Highest_Score, ROUND(AVG(Runs),2) AS Batting_Average,
    ROUND(SUM(Runs)*100.0/SUM(Balls),2) AS Strike_Rate,
    SUM(`4s`) AS Fours, SUM(`6s`) AS Sixes,
    SUM(CASE WHEN Runs>=50 THEN 1 ELSE 0 END) AS Fifties,
    SUM(CASE WHEN Runs>=100 THEN 1 ELSE 0 END) AS Hundreds,
    SUM(CASE WHEN Dismissal='Not Out' THEN 1 ELSE 0 END) AS Not_Outs
FROM Batting b JOIN BestBatter bb
ON b.Player=bb.Player GROUP BY b.Player;


# 12. STATS OF BEST BOWLER
WITH BestBowler AS
( SELECT
        Bowler, SUM(Wickets) AS Total_Wickets
    FROM Bowling
    GROUP BY Bowler
    ORDER BY Total_Wickets DESC LIMIT 1)
SELECT b.Bowler,
COUNT(*) Matches, SUM(Wickets) Total_Wickets,
ROUND(AVG(Wickets),2) Avg_Wickets,
MIN(Economy) Best_Economy,
ROUND(AVG(Economy),2) Avg_Economy,
SUM(Maidens) Maidens, MAX(Wickets) Best_Bowling,
SUM(RunsConceded) Runs_Conceded, SUM(Overs) Overs_Bowled
FROM Bowling b JOIN BestBowler bw ON b.Bowler=bw.Bowler
GROUP BY b.Bowler;