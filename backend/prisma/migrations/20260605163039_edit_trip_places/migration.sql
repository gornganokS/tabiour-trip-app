/*
  Warnings:

  - The primary key for the `Place` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `placeId` on the `Place` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[tripId,id]` on the table `Place` will be added. If there are existing duplicate values, this will fail.
  - The required column `id` was added to the `Place` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.

*/
-- DropIndex
DROP INDEX "Place_tripId_placeId_key";

-- AlterTable
ALTER TABLE "Place" DROP CONSTRAINT "Place_pkey",
DROP COLUMN "placeId",
ADD COLUMN     "id" TEXT NOT NULL,
ADD CONSTRAINT "Place_pkey" PRIMARY KEY ("id");

-- CreateIndex
CREATE UNIQUE INDEX "Place_tripId_id_key" ON "Place"("tripId", "id");
