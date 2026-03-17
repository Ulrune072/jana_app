const express = require('express');
const cors    = require('cors');

const authMiddleware   = require('./middleware/auth.middleware');
const errorMiddleware  = require('./middleware/error.middleware');
const authRouter       = require('./modules/auth/auth.router');
const biomarkersRouter = require('./modules/biomarkers/biomarkers.router');
const alertsRouter     = require('./modules/alerts/alerts.router');
const chatbotRouter    = require('./modules/chatbot/chatbot.router');
const profileRouter    = require('./modules/profile/profile.router'); // new

const app = express();

app.use(cors({ origin: '*', allowedHeaders: ['Content-Type', 'Authorization'] }));
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/api', authMiddleware);
app.use('/api/auth',       authRouter);
app.use('/api/profile',    profileRouter);   // new
app.use('/api/biomarkers', biomarkersRouter);
app.use('/api/alerts',     alertsRouter);
app.use('/api/chatbot',    chatbotRouter);

app.use(errorMiddleware);

module.exports = app;
