# import libraries needed
library(tidyr)
library(dplyr)
library("recommenderlab")
library("scales")

# import that dataset to be used
full_data <- read.csv("full_df.csv")
org_df <- read.csv("full_dataset.csv")

# use the playcount to create a rating of 1-5 for each song
vec_full <- full_data$play_count
rating_norm_full <- rescale(vec_full, to = c(1, 5))

# add the ratings to the dataset
full_data$rating <- rating_norm_full

# remove the unnecessary columns from the dataset
# for the recommender systems only user_id, song, and rating are necessary
full_data = subset(full_data, select = -c(X, play_count, song_id, pronoun, genre_1, genre_2, genre_3))

org_df = subset(org_df, select = -c(X, song_id, user_id, play_count))
org_df <- org_df[!(org_df$pronoun=="they/them/she/her"),]

org_df_gender_count = org_df %>%
  group_by(pronoun) %>%
  summarise(n = n()) %>%
  mutate(Freq = n/sum(n))

# format the dataset into type "realRatingMatrix"
full_data$user_id <- as.factor(full_data$user_id)
full_data$song <- as.factor(full_data$song)
full_data$rating <- as.numeric(full_data$rating)
full_data_m <- as(full_data, "realRatingMatrix")

# split the data into train and test
train <- full_data_m[1:2007]
#test <- full_data_m[2008:2041]


# Train each recommender systems on the train data
# HybridRecommender
system.time(
  recomHyb <- HybridRecommender(
    Recommender(train, method = "POPULAR"),
    Recommender(train, method = "RANDOM"),
    Recommender(train, method = "RERECOMMEND"),
    Recommender(train, method = "UBCF"),
    weights = c(.50, .05, .25, .20))
)

# UBCF Recommender
recomUBCF <- Recommender(train, method = "UBCF")

# Rerecommend Recommender
recomRerec <- Recommender(train, method = "RERECOMMEND")

# Create dataframe to hold the results of our recommender system analysis
gender_dif_df <- data.frame(matrix(ncol=6,nrow=0, dimnames=list(NULL, c("hyb_dif_male", "hyb_dif_female", "ubcf_dif_male", "ubcf_dif_female", "rerec_dif_male", "rerec_dif_female"))))
weight_df <- data.frame(matrix(ncol=6,nrow=0, dimnames=list(NULL, c("hyb_weight_male", "hyb_weight_female", "ubcf_weight_male", "ubcf_weight_female", "rerec_weight_male", "rerec_weight_female"))))

i <- 0
while (i < 500) {
  
  skip_to_next <- FALSE
  
  curr_test = sample(full_data_m, 34)
  tryCatch(
    {
      # Have each recommender systems provide 5 recommendations for 34 users
    
      # HybridRecommender
      predHyb <- predict(recomHyb, 1:34, data = curr_test, type = "topNList", n = 5)
      recsHyb <- data.frame(as(predHyb, "list"))
      
      # UBCF Recommender
      preUBCF <- predict(recomUBCF, curr_test, n = 5)
      recsUBCF <- data.frame(as(preUBCF, "list"))
      
      # Rerecommend Recommender
      preRerec <- predict(recomRerec, curr_test, n = 5)
      recsRerec <- data.frame(as(preRerec, "list"))
      
      # Add all the recommendations for each rec system into on file per recommender
      stacked_Hyb <- stack(recsHyb)
      stacked_UBCF <- stack(recsUBCF)
      stacked_Rerec <- stack(recsRerec)
      
      # Add weights to all of the recommendations 5-1 for each user
      weights<-rep(c(5,4,3,2,1),times=34)
      stacked_Hyb$weights<-weights
      stacked_UBCF$weights<-weights
      stacked_Rerec$weights<-weights
      weighted_Hyb = subset(stacked_Hyb, select = -c(ind))
      weighted_UBCF = subset(stacked_UBCF, select = -c(ind))
      weighted_Rerec = subset(stacked_Rerec, select = -c(ind))
      
      # Format the list of weighted recommendations to be used for analysis
      weighted_Hyb = separate(data = weighted_Hyb, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
      weighted_UBCF = separate(data = weighted_UBCF, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
      weighted_Rerec = separate(data = weighted_Rerec, col = values, into = c("song", "artist", "pronoun", "genre_1", "genre_2", "genre_3"), sep = "\\~")
    },
    error = function(e) { skip_to_next <<- TRUE}
  )
  
  if(skip_to_next) { next }
  
  tryCatch(
    {
      # Gender Analysis
      hyb_df_gender_count = weighted_Hyb %>%
        group_by(pronoun) %>%
        summarise(n = n()) %>%
        mutate(Freq = n/sum(n))
      
      ubcf_df_gender_count = weighted_UBCF %>%
        group_by(pronoun) %>%
        summarise(n = n()) %>%
        mutate(Freq = n/sum(n))
      
      rerec_df_gender_count = weighted_Rerec %>%
        group_by(pronoun) %>%
        summarise(n = n()) %>%
        mutate(Freq = n/sum(n))
      
      # Calculate the difference in frequence between the total dataset and the recommender systems
      gender_count_df = data.frame(org=org_df_gender_count, hyb=hyb_df_gender_count, ubcf=ubcf_df_gender_count, rerec=rerec_df_gender_count, check.names=F)
      
      gender_count_df$hyb.dif <- (round((100 * (gender_count_df$org.Freq - gender_count_df$hyb.Freq)), digits = 2))
      gender_count_df$ubcf.dif <- (round((100 * (gender_count_df$org.Freq - gender_count_df$ubcf.Freq)), digits = 2))
      gender_count_df$rerec.dif <- (round((100 * (gender_count_df$org.Freq - gender_count_df$rerec.Freq)), digits = 2))
      
      #append the result to a list 
      gender_dif_df[nrow(gender_dif_df) + 1,] <- list(gender_count_df$hyb.dif[1], gender_count_df$hyb.dif[2], gender_count_df$ubcf.dif[1], gender_count_df$ubcf.dif[2], gender_count_df$rerec.dif[1], gender_count_df$rerec.dif[2])
      
      # Weight Analysis
      hyb_df_weight_count = weighted_Hyb %>%
        group_by(pronoun) %>%
        summarise( n = n(), weight=sum(weights)) %>%
        mutate(Avg_Weight = round(weight/n, digits = 2))
      
      ubcf_df_weight_count = weighted_UBCF %>%
        group_by(pronoun) %>%
        summarise( n = n(), weight=sum(weights)) %>%
        mutate(Avg_Weight = round(weight/n, digits = 2))
      
      rerec_df_weight_count = weighted_Rerec %>%
        group_by(pronoun) %>%
        summarise( n = n(), weight=sum(weights)) %>%
        mutate(Avg_Weight = round(weight/n, digits = 2))
      
      #append the result to a list 
      weight_df[nrow(weight_df) + 1,] <- list(hyb_df_weight_count$Avg_Weight[1], hyb_df_weight_count$Avg_Weight[2], ubcf_df_weight_count$Avg_Weight[1], ubcf_df_weight_count$Avg_Weight[2], rerec_df_weight_count$Avg_Weight[1], rerec_df_weight_count$Avg_Weight[2])
    },
    error = function(e) { skip_to_next <<- TRUE}
  )
  
  if(skip_to_next) { next }
  i = i+1
}

# Calculate confidence intervals

# Gender
gender_sorted <- gender_dif_df[order(gender_dif_df$hyb_dif_male),]
gender_conf_hby_m_lower <- gender_sorted$hyb_dif_male[13]
gender_conf_hby_m_upper <- gender_sorted$hyb_dif_male[487]

gender_sorted <- gender_dif_df[order(gender_dif_df$hyb_dif_female),]
gender_conf_hyb_f_lower <- gender_sorted$hyb_dif_female[13]
gender_conf_hyb_f_upper <- gender_sorted$hyb_dif_female[487]

gender_sorted <- gender_dif_df[order(gender_dif_df$ubcf_dif_male),]
gender_conf_ubcf_m_lower <- gender_sorted$ubcf_dif_male[13]
gender_conf_ubcf_m_upper <- gender_sorted$ubcf_dif_male[487]

gender_sorted <- gender_dif_df[order(gender_dif_df$ubcf_dif_female),]
gender_conf_ubcf_f_lower <- gender_sorted$ubcf_dif_female[13]
gender_conf_ubcf_f_upper <- gender_sorted$ubcf_dif_female[487]

gender_sorted <- gender_dif_df[order(gender_dif_df$rerec_dif_male),]
gender_conf_rerec_m_lower <- gender_sorted$rerec_dif_male[13]
gender_conf_rerec_m_upper <- gender_sorted$rerec_dif_male[487]

gender_sorted <- gender_dif_df[order(gender_dif_df$rerec_dif_female),]
gender_conf_rerec_f_lower <- gender_sorted$rerec_dif_female[13]
gender_conf_rerec_f_upper <- gender_sorted$rerec_dif_female[487]

# Weight
weight_sorted <- weight_df[order(weight_df$hyb_weight_male),]
weight_conf_hyb_m_lower <- weight_sorted$hyb_weight_male[13]
weight_conf_hyb_m_upper <- weight_sorted$hyb_weight_male[487]

weight_sorted <- weight_df[order(weight_df$hyb_weight_female),]
weight_conf_hyb_f_lower <- weight_sorted$hyb_weight_female[13]
weight_conf_hyb_f_upper <- weight_sorted$hyb_weight_female[487]

weight_sorted <- weight_df[order(weight_df$ubcf_weight_male),]
weight_conf_ubcf_m_lower <- weight_sorted$ubcf_weight_male[13]
weight_conf_ubcf_m_upper <- weight_sorted$ubcf_weight_male[487]

weight_sorted <- weight_df[order(weight_df$ubcf_weight_female),]
weight_conf_ubcf_f_lower <- weight_sorted$ubcf_weight_female[13]
weight_conf_ubcf_f_upper <- weight_sorted$ubcf_weight_female[487]

weight_sorted <- weight_df[order(weight_df$rerec_weight_male),]
weight_conf_rerec_m_lower <- weight_sorted$rerec_weight_male[13]
weight_conf_rerec_m_upper <- weight_sorted$rerec_weight_male[487]

weight_sorted <- weight_df[order(weight_df$rerec_weight_female),]
weight_conf_rerec_f_lower <- weight_sorted$rerec_weight_female[13]
weight_conf_rerec_f_upper <- weight_sorted$rerec_weight_female[487]