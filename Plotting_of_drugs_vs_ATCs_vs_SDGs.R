Drug_Reaction_Observed_Yearly <- read.csv("~/SQL Server Management Studio/Drug_Reaction_Observed_Yearly.csv", header=FALSE)
names(Drug_Reaction_Observed_Yearly) <- c("Year", "DRecNo", "SubstanceName", "PTCode", "ReactionName", "NObserved")
Drug_Reaction_Observed_Yearly$Year[1] <- 2014

Drug_Reaction_NDrug_NReaction_Yearly <- read.csv("~/SQL Server Management Studio/Drug_Reaction_NDrug_NReaction_Yearly.csv", header=FALSE)
View(Drug_Reaction_NDrug_NReaction_Yearly)
names(Drug_Reaction_NDrug_NReaction_Yearly) <- c("Year", "SubstanceName", "NDrug", "ReactionName", "NReaction")
Drug_Reaction_NDrug_NReaction_Yearly$Year[1] <- 2014

Year_Ntot <- read.csv("~/SQL Server Management Studio/Year_Ntot.csv", header=FALSE)
View(Year_Ntot)
names(Year_Ntot) <- c("Year", "Ntot")
Drug_Reaction_NDrug_NReaction_Yearly$Year[1] <- 2014
Year_Ntot$V1[1] <- as.numeric(2014)
#rm(Year_Ntot)

Year_Ntot_Asc <- Year_Ntot[order(Year_Ntot$Year),]
Year_Ntot_Asc$Ntot <- cumsum(Year_Ntot_Asc$Ntot)

Drug_Reaction_NDrug_NReaction_Yearly <- Drug_Reaction_NDrug_NReaction_Yearly[order(Drug_Reaction_NDrug_NReaction_Yearly$Year),]
Drug_Reaction_NDrug_NReaction_Yearly$NDrug <- ave(Drug_Reaction_NDrug_NReaction_Yearly$NDrug, Drug_Reaction_NDrug_NReaction_Yearly$SubstanceName, FUN = cumsum)
Drug_Reaction_NDrug_NReaction_Yearly$NReaction <- ave(Drug_Reaction_NDrug_NReaction_Yearly$NReaction, Drug_Reaction_NDrug_NReaction_Yearly$ReactionName, FUN = cumsum)

Drug_Reaction_NDrug_NReaction_Ntot_Yearly <- merge(Drug_Reaction_NDrug_NReaction_Yearly, Year_Ntot_Asc, by = "Year")
Drug_Reaction_NDrug_NReaction_Ntot_Yearly$NExpected <- (as.numeric(Drug_Reaction_NDrug_NReaction_Ntot_Yearly$NDrug) * as.numeric(Drug_Reaction_NDrug_NReaction_Ntot_Yearly$NReaction))/as.numeric(Drug_Reaction_NDrug_NReaction_Ntot_Yearly$Ntot)

#rm(Drug_Reaction_NDrug_NReaction_Ntot_Yearly)

library(dplyr)
Drug_Reaction__NExpected_Yearly <- select(Drug_Reaction_NDrug_NReaction_Ntot_Yearly$Year, Drug_Reaction_NDrug_NReaction_Ntot_Yearly$SubstanceName, Drug_Reaction_NDrug_NReaction_Ntot_Yearly$ReactionName, Drug_Reaction_NDrug_NReaction_Ntot_Yearly$NExpected)
Drug_Reaction__NExpected_Yearly <- select(Drug_Reaction_NDrug_NReaction_Ntot_Yearly, 1,2,4,7)

#rm(Drug_Reaction__NExpected_Yearly)

Drug_Reaction_Observed_Yearly_Altered <- select(Drug_Reaction_Observed_Yearly, 1,3,5,6)


Drug_Reaction_Observed_Expected_Yearly <- merge(Drug_Reaction_Observed_Yearly_Altered, Drug_Reaction__NExpected_Yearly, by = c("Year", "SubstanceName", "ReactionName"))

#rm(Drug_Reaction_Observed_Expected_Yearly)

Drug_Reaction_Observed_Expected_Yearly$IC <- log2((Drug_Reaction_Observed_Expected_Yearly$NObserved + 0.5)/(Drug_Reaction_Observed_Expected_Yearly$NExpected +0.5))
