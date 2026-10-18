-- CreateEnum
CREATE TYPE "MatchStatus" AS ENUM ('lobby', 'in_progress', 'finished');

-- CreateEnum
CREATE TYPE "GameStatus" AS ENUM ('waiting', 'dealing', 'in_progress', 'finished');

-- CreateEnum
CREATE TYPE "Direction" AS ENUM ('clockwise', 'counterclockwise');

-- CreateTable
CREATE TABLE "players" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "display_name" VARCHAR(32) NOT NULL,
    "session_token" VARCHAR(128) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "players_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "matches" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "room_code" VARCHAR(8) NOT NULL,
    "status" "MatchStatus" NOT NULL DEFAULT 'lobby',
    "host_player_id" UUID NOT NULL,
    "player_count" INTEGER NOT NULL,
    "started_at" TIMESTAMPTZ,
    "ended_at" TIMESTAMPTZ,

    CONSTRAINT "matches_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "match_players" (
    "match_id" UUID NOT NULL,
    "player_id" UUID NOT NULL,
    "seat_index" INTEGER NOT NULL,

    CONSTRAINT "match_players_pkey" PRIMARY KEY ("match_id","player_id")
);

-- CreateTable
CREATE TABLE "games" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "match_id" UUID NOT NULL,
    "game_number" INTEGER NOT NULL,
    "status" "GameStatus" NOT NULL DEFAULT 'waiting',
    "started_player_id" UUID,
    "direction" "Direction" NOT NULL DEFAULT 'clockwise',
    "started_at" TIMESTAMPTZ,
    "ended_at" TIMESTAMPTZ,

    CONSTRAINT "games_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "game_rankings" (
    "game_id" UUID NOT NULL,
    "player_id" UUID NOT NULL,
    "finish_rank" INTEGER NOT NULL,

    CONSTRAINT "game_rankings_pkey" PRIMARY KEY ("game_id","player_id")
);

-- CreateTable
CREATE TABLE "game_events" (
    "id" BIGSERIAL NOT NULL,
    "game_id" UUID NOT NULL,
    "player_id" UUID,
    "event_type" VARCHAR(64) NOT NULL,
    "payload" JSONB NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "game_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "players_session_token_key" ON "players"("session_token");

-- CreateIndex
CREATE UNIQUE INDEX "matches_room_code_key" ON "matches"("room_code");

-- CreateIndex
CREATE INDEX "game_events_game_id_idx" ON "game_events"("game_id");

-- AddForeignKey
ALTER TABLE "matches" ADD CONSTRAINT "matches_host_player_id_fkey" FOREIGN KEY ("host_player_id") REFERENCES "players"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "match_players" ADD CONSTRAINT "match_players_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "players"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "games" ADD CONSTRAINT "games_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "matches"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "games" ADD CONSTRAINT "games_started_player_id_fkey" FOREIGN KEY ("started_player_id") REFERENCES "players"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "game_rankings" ADD CONSTRAINT "game_rankings_game_id_fkey" FOREIGN KEY ("game_id") REFERENCES "games"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "game_rankings" ADD CONSTRAINT "game_rankings_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "players"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "game_events" ADD CONSTRAINT "game_events_game_id_fkey" FOREIGN KEY ("game_id") REFERENCES "games"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "game_events" ADD CONSTRAINT "game_events_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "players"("id") ON DELETE SET NULL ON UPDATE CASCADE;
