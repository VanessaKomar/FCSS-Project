# install.packages("recommenderlab")
# install.packages('dplyr')
#install.packages("tidyr")
library("recommenderlab")
library("scales")

full_data <- read.csv("full_df.csv")
#full_data <- read.csv("data_merged.csv")

vec_full <- full_data$play_count
rating_norm_full <- rescale(vec_full, to = c(1, 5))

full_data$rating <- rating_norm_full

#full_data = subset(full_data, select = -c(X, play_count))
full_data = subset(full_data, select = -c(X, play_count, song_id, pronoun, genre_1, genre_2, genre_3))

full_data$user_id <- as.factor(full_data$user_id)
full_data$song <- as.factor(full_data$song)
full_data$rating <- as.numeric(full_data$rating)
full_data_m <- as(full_data, "realRatingMatrix")

#train <- full_data_m[1:1302]
#test <- full_data_m[1303:1628]

#train <- full_data_m[1:1536]
#test <- full_data_m[1537:1921]

train <- full_data_m[1:2007]
test <- full_data_m[2008:2041]

# Compute HybridRecommender
system.time(
  recomHyb <- HybridRecommender(
    #Recommender(train, method = "IBCF"),
    Recommender(train, method = "POPULAR"),
    Recommender(train, method = "RANDOM"),
    Recommender(train, method = "RERECOMMEND"),
    Recommender(train, method = "UBCF"),
    weights = c(.50, .05, .25, .20))
)

predHyb <- predict(recomHyb, 1:34, data = test, type = "topNList", n = 5)
recsHyb <- data.frame(as(predHyb, "list"))

recomUBCF <- Recommender(train, method = "UBCF")
preUBCF <- predict(recomUBCF, test, n = 5)
recsUBCF <- data.frame(as(preUBCF, "list"))

recomRerec <- Recommender(train, method = "RERECOMMEND")
preRerec <- predict(recomRerec, test, n = 5)
recsRerec <- data.frame(as(preRerec, "list"))

stacked_Hyb <- stack(recsHyb)
stacked_UBCF <- stack(recsUBCF)
stacked_Rerec <- stack(recsRerec)

weights<-rep(c(5,4,3,2,1),times=34)
stacked_Hyb$weights<-weights
stacked_UBCF$weights<-weights
stacked_Rerec$weights<-weights
weighted_Hyb = subset(stacked_Hyb, select = -c(ind))
weighted_UBCF = subset(stacked_UBCF, select = -c(ind))
weighted_Rerec = subset(stacked_Rerec, select = -c(ind))

weighted_Hyb = separate(data = weighted_Hyb, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
weighted_UBCF = separate(data = weighted_UBCF, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
weighted_Rerec = separate(data = weighted_Rerec, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
