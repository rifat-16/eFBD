import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

/**
 * Scheduled function to reset monthly stats for all players.
 * Runs at midnight (00:00) on the 1st day of every month.
 */
export const resetMonthlyStats = functions.pubsub
  .schedule("0 0 1 * *")
  .onRun(async (context) => {
    const playersRef = db.collection("players");
    const snapshot = await playersRef.get();

    if (snapshot.empty) {
      console.log("No players found to reset stats.");
      return null;
    }

    const now = new Date();
    // We run on the 1st of the month, so we are archiving the PREVIOUS month's stats.
    const lastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const monthName = lastMonth.toLocaleString('default', { month: 'long' });
    const year = lastMonth.getFullYear();
    const seasonId = `${year}-${(lastMonth.getMonth() + 1).toString().padStart(2, '0')}`;

    // 1. Prepare Archive Data
    const playersData = snapshot.docs.map(doc => {
        const data = doc.data();
        return {
            uid: data.uid,
            ign: data.ign,
            points: data.monthlyPoints || 0,
            wins: data.monthlyWins || 0,
            draws: data.monthlyDraws || 0,
            losses: data.monthlyLosses || 0,
            gf: data.monthlyGoalsFor || 0,
            ga: data.monthlyGoalsAgainst || 0,
        };
    });

    // Sort by points, then GD, then GF
    playersData.sort((a, b) => {
        if (b.points !== a.points) return b.points - a.points;
        const gdA = a.gf - a.ga;
        const gdB = b.gf - b.ga;
        if (gdB !== gdA) return gdB - gdA;
        return b.gf - a.gf;
    });

    // Take top 100 for the archive to save space
    const topPlayers = playersData.slice(0, 100);

    // 2. Save Archive
    await db.collection("season_history").doc(seasonId).set({
        seasonId,
        month: monthName,
        year: year,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        standings: topPlayers,
    });

    // 3. Reset Stats in Batches (Firestore batches have a limit of 500)
    const chunks = [];
    for (let i = 0; i < snapshot.docs.length; i += 500) {
        chunks.push(snapshot.docs.slice(i, i + 500));
    }

    for (const chunk of chunks) {
        const batch = db.batch();
        chunk.forEach((doc) => {
            batch.update(doc.ref, {
                monthlyPoints: 0,
                monthlyGoalsFor: 0,
                monthlyGoalsAgainst: 0,
                monthlyWins: 0,
                monthlyDraws: 0,
                monthlyLosses: 0,
                monthlyMatchesPlayed: 0,
            });
        });
        await batch.commit();
    }

    console.log(`Successfully archived season ${seasonId} and reset monthly stats for ${snapshot.size} players.`);
    return null;
  });
