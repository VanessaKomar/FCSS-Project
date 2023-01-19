# FCSS-Project

Project registration
Project title: Bias and Fairness in Recommender Systems

Names and email addresses of group members:
Marc Velmeden, marc.velmeden@edu.uni-graz.at (Business Administration)
Robert Oswald, robert.oswald@edu.uni-graz.at (Business Administration)
Antonia Sendlhofer, antonia.sendlhofer@edu.uni-graz.at (Sociology)
Vanessa Komar, vanessa.komar@edu.uni-graz.at (Computer Science & Cognitive Science)

Research question(s):
We aim to test the hypothesis of the role of bias in recommender systems. We will study how the gender of musical artists influences the recommendations given by recommender systems. To do so, we will focus on three different recommender systems and analyze the output recommendations by these systems through the input of datasets that include the gender of musical artists in order to determine if these recommender systems have a gender bias.
We will test the following hypotheses:

The number of recommended songs by male artists is proportionately higher than that of female artists.

The mean of the ranked recommendations of songs by male artists is higher than that of female artists.

The genre that we believe will be male dominated/biased is rap.

Planned data retrieval and analysis to address the questions

We plan the following steps


Based on the existing datasets (d1) (d2) (d3) (d4), combine the datasets by retrieving 10,000 songs from the first dataset, the artists’ gender from the second dataset, and userdata from the third dataset.

Clean the dataset by removing any songs that are incomplete in the gender section. For the sake of this project we will also remove any non-binary artists or any songs that have artists with ambiguous genders (i.e. songs with multiple artists of varying genders).

Normalize the dataset in order to have an equal representation of male and female artists.

Run our dataset on recommender systems from the Python RecLab (https://github.com/gasevi/pyreclab).

Record the top 100 songs that each recommender system produced and test our hypotheses. 
See how this compares to the proportions of male to female in the Dataset
Weight each song weight (top song gets a weight of 100,  song 100 gets weight 1)
Calculate the weighted total of male songs and female songs
See how this compares to the proportions of male to female in Dataset

Create a bar graph to visualize the ratio between male and female artists with each bar being a recommender system. 


(d1) Songs: http://millionsongdataset.com/
(d2) Male/Female: https://makemusicequal.chartmetric.com/pronoun-gender-database
(d3) Userdata: http://millionsongdataset.com/tasteprofile/ (Play counts)
(d4) LastFM: http://millionsongdataset.com/lastfm/
PyRecLab: https://github.com/gasevi/pyreclab
