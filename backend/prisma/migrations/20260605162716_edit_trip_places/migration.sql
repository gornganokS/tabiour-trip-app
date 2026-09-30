/*
  Warnings:

  - The primary key for the `Place` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `id` on the `Place` table. All the data in the column will be lost.
  - A unique constraint covering the columns `[tripId,placeId]` on the table `Place` will be added. If there are existing duplicate values, this will fail.
  - The required column `placeId` was added to the `Place` table with a prisma-level default value. This is not possible if the table is not empty. Please add this column as optional, then populate it before making it required.

*/
-- AlterTable
ALTER TABLE "Place" DROP CONSTRAINT "Place_pkey",
DROP COLUMN "id",
ADD COLUMN     "placeId" TEXT NOT NULL,
ADD CONSTRAINT "Place_pkey" PRIMARY KEY ("placeId");

-- CreateIndex
CREATE UNIQUE INDEX "Place_tripId_placeId_key" ON "Place"("tripId", "placeId");
