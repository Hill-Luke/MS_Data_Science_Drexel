library(dplyr)
library(tidyverse)
library(tidyr)
library(igraph)
library(ggplot2)
library(networkD3)
library(network)
library(ggraph)
library(gtools)
library(DT)
library(shiny)
library(shinydashboard)
library(scales)
library(stringi)
library(visNetwork)
library(centiserve)
library(shinyWidgets)
library(tidytext)
library(widyr)
library(ngram)
options(scipen=999)
# Delimited by sentence
fellow<-read.delim("C:/Users/lukeh/OneDrive/Desktop/Grad School/LOTR_text/01 - The Fellowship Of The Ring.txt")
tt<-read.delim("C:/Users/lukeh/OneDrive/Desktop/Grad School/LOTR_text/02 - The Two Towers.txt")
rotk<-read.delim("C:/Users/lukeh/OneDrive/Desktop/Grad School/LOTR_text/03 - The Return of the King.txt")


# Adding a chapter structure

fellow<-fellow %>%  mutate(text=THE.FELLOWSHIP.OF.THE.RING,
                   book='The Fellowship of the Ring',
                   chapter = cumsum(str_detect(THE.FELLOWSHIP.OF.THE.RING, regex( "^                           _Chapter ", ignore_case = TRUE)))) %>% 
  ungroup()
fellow$THE.FELLOWSHIP.OF.THE.RING<-NULL
fellow$text<-fellow$text %>% trimws()



tt<-tt %>%  mutate(text=THE.TWO.TOWERS,
                  book='The Two Towers',
                  chapter = cumsum(str_detect(THE.TWO.TOWERS, regex( "^                           _Chapter ", ignore_case = TRUE)))) %>% 
  ungroup()
tt$THE.TWO.TOWERS<-NULL

# Getting rid of excess whitespace
tt$text<-tt$text %>% trimws()

# ROTK
rotk<-rotk %>%  mutate(text=THE.RETURN.OF.THE.KING,
                   book='The Return of the King',
                   chapter = cumsum(str_detect(THE.RETURN.OF.THE.KING, regex( "^                           _Chapter ", ignore_case = TRUE)))) %>% 
  ungroup()
rotk$THE.RETURN.OF.THE.KING<-NULL

# Getting rid of excess whitespace
rotk$text<-rotk$text %>% trimws()


# Putting all three together
lotr<-rbind(fellow, tt, rotk)


View(lotr)



# Restructuring for one token per row
lotr_words<-lotr %>% unnest_tokens(word, text)

# Dropping stop words
lotr_words<-lotr_words %>% anti_join(get_stopwords())

# Sentiment Analysis for fellowship of the Ring
################################################
positive<-get_sentiments('bing') %>% filter(sentiment=='positive')

lotr_words %>% filter(book=='The Fellowship of the Ring') %>% semi_join(positive) %>% 
  count(word, sort=T) %>% head(10)


# Most common words in fellowship of the ring
################################################
# Restructuring for one token per row
lotr_words<-lotr %>% unnest_tokens(word, text)

# Dropping stop words
lotr_words<-lotr_words %>% anti_join(get_stopwords())
book_words <- lotr_words  
book_words$chapter<-NULL 
book_words<-book_words %>% count(book, word, sort=T) 
book_words$book <-as.factor(book_words$book)


# Getting all words in each book
total_words <- book_words %>% group_by(book) %>% summarize('total'=sum(n))
book_words <- left_join(book_words, total_words) 


ggplot(book_words, aes(n/total, fill = book)) +
  geom_histogram(show.legend = FALSE) +
  xlim(NA, 0.0009) +
  facet_wrap(~book, ncol = 2, scales = "free_y")

# Rank Frequency
#################################################

freq_by_rank <- book_words %>% 
  group_by(book) %>% 
  dplyr::mutate(rank = row_number(), `term frequency` = n/total) %>%
  ungroup()


book_tf_idf <- book_words %>%
  bind_tf_idf(word, book, n)


# Ngram analysis for Fellowship of the Ring 
################################################
fellow<- lotr %>% filter(book=='The Fellowship of the Ring')
fellow_bigram<-fellow %>%
  unnest_tokens(bigram, text, token = "ngrams", n = 2) %>%
  filter(!is.na(bigram))  %>%   
  separate(bigram, c("word1", "word2"), sep = " ") %>% 
  filter(!word1 %in% stop_words$word) %>%
  filter(!word2 %in% stop_words$word) %>% 
  unite(bigram, word1, word2, sep = " ") %>%
   count(bigram, sort = TRUE)
  

# Correlation Analysis in Paragraph form
################################################

lotr_paragraphs<-lotr

fellow_paragraphs_words<-lotr_paragraphs %>% 
                      filter(book=="The Fellowship of the Ring") %>% 
                      mutate(paragraphs = row_number()) %>%
                      filter(chapter > 0) %>%
                      unnest_tokens(word, text) %>%
                      filter(!word %in% stop_words$word) 


word_cors <- fellow_paragraphs_words %>%
  group_by(word) %>%
  filter(n() >= 20) %>%
  pairwise_cor(word, paragraphs, sort = TRUE) %>% 
  filter(correlation!=1)


# Subsetting to only term frequent words to see if we can get a character list

# Setting an arbitrary threshold of 0.001 term frequency
fellow_tf<-book_tf_idf %>% filter(book=="The Fellowship of the Ring") %>% filter(tf>0.001)

# Subsetting the correlations list to only those words that appear in the term frequency list
fellow_cor<-word_cors %>% filter(item1 %in% fellow_tf$word)

