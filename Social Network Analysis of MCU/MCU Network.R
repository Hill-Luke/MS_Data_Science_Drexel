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

nodes<-read.csv("C:/Users/lukeh/OneDrive/Desktop/Grad School/Winter Qtr 23/Final Project Datasets/MCU/nodes.csv")
og_edges<-read.csv("C:/Users/lukeh/OneDrive/Desktop/Grad School/Winter Qtr 23/Final Project Datasets/MCU/hero-network.csv")

options(max.print=1000000)
options(scipen=999)


# Subsetting to heroes only
# nodes<-nodes$node %>% data.frame()
nodes<-nodes %>% rename('hero'='node')


from<-select(og_edges, c('hero1')) %>% data.frame()
from<-from %>% rename('hero'='hero1')
from<-left_join(from,nodes,by='hero')

to<-select(og_edges, c('hero2')) %>% data.frame()
to<-to %>% rename('hero'='hero2')
to<-left_join(to,nodes,by='hero')

edges<-data.frame(from,to)


node_heroes<-subset(nodes, type=='hero') %>% unique()

edges_heroes<-subset(edges, type=='hero' & type.1=='hero')
edges_heroes<-edges_heroes %>% rename('from'='hero',
                                      'to'='hero.1')
edges_heroes<-select(edges_heroes,c('from','to'))


# Removing Loops!
edges_heroes<-subset(edges_heroes, from!=to)

# Removing duplicates!

edges_heroes<-edges_heroes %>% unique()



#Creating a simplified network object
G <- network(edges_heroes,
                     vertex.attr = node_heroes,
                     matrix.type = "edgelist",
                     ignore.eval = FALSE)

G2<-graph_from_data_frame(edges_heroes,directed=T,vertices=node_heroes)



# Network is enormous, so I need to trim connections

# Getting rid of isolated connections
Isolated = which(degree(G2)==0)
G2 = igraph::delete.vertices(G2, Isolated)

LO = layout_with_fr(G2)

# Lots of sub networks, needs further trimming.


# Removing connections with only one other connection to help make the network more visible.
single_connection = which(degree(G2)==1)
G3 = igraph::delete.vertices(G2, single_connection)

# Still very large
few_connections = which(degree(G3) %in% c(0,1,2,3,4,5))
G4 = igraph::delete.vertices(G3, few_connections)


# Plotting the network
visIgraph(
  G4,
  idToLabel = TRUE,
  layout = "layout_nicely",
  physics = FALSE,
  smooth = FALSE,
  type = "square",
  randomSeed = NULL,
  layoutMatrix = NULL)

#########################
# Trimming subnetworks

# Subnet 1

'%notin%'<-Negate('%in%')

##########################
# main nodes of subnet 1
main_nodes<-c('MISS THING/MARY','SWORDSMAN IV/','AMAZO-MAXI-WOMAN/','PANTHER CUB/','STERLING','MANT/ERNEST','DARLEGUNG, GEN.')
to_trim<-subset(edges_heroes, edges_heroes$to %in% main_nodes)

from_trim<-subset(edges_heroes, edges_heroes$from %in% main_nodes)
to_trim<-row.names(to_trim)
from_trim<-row.names(from_trim)

#Removing nodes
node_heroes<-subset(node_heroes, hero %notin% main_nodes )

#Removing Edges
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% from_trim)
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% to_trim)

##########################
# main nodes of subnet 2
main_nodes<-c('OSWALD','ORWELL','NILES, SEN. CATHERIN','LUDLUM, ROSS','HOFFMAN','FAGIN','ASHER, MICHAEL','ASHER, DONNA','ASHER, CARL')
to_trim<-subset(edges_heroes, edges_heroes$to %in% main_nodes)

from_trim<-subset(edges_heroes, edges_heroes$from %in% main_nodes)
to_trim<-row.names(to_trim)
from_trim<-row.names(from_trim)

#Removing nodes
node_heroes<-subset(node_heroes, hero %notin% main_nodes )

#Removing Edges
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% from_trim)
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% to_trim)

##########################
# main nodes of subnet 3
main_nodes<-c('CRIMINSON DYNAMO VIII/','RADIOACTIVE MAN II/D','KRANG II','BLACK KNIGHT VI/PROF','WHIRLWIND II/DAVID C','MELTER II/BRUNO HORG','TITANIUM MAN III/BOR')
to_trim<-subset(edges_heroes, edges_heroes$to %in% main_nodes)

from_trim<-subset(edges_heroes, edges_heroes$from %in% main_nodes)
to_trim<-row.names(to_trim)
from_trim<-row.names(from_trim)

#Removing nodes
node_heroes<-subset(node_heroes, hero %notin% main_nodes )

#Removing Edges
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% from_trim)
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% to_trim)

#############################


# Recreating the graph
G5<-graph_from_data_frame(edges_heroes,directed=T,vertices=node_heroes)
few_connections = which(degree(G5) %in% c(0,1,2,3,4,5))
G5 = igraph::delete.vertices(G5, few_connections)



# Checking the closeness centrality
hero_closeness<-closeness(G5) %>% data.frame()
hero_closeness$hero<-rownames(hero_closeness)
# Closeness looks suspect, as you have several minor characters with very high closeness



# Creating a quick list of edges for a minor character to check.
main_nodes<-c('BENNETT, MITCH')
to_trim<-subset(edges_heroes, edges_heroes$to %in% main_nodes)

from_trim<-subset(edges_heroes, edges_heroes$from %in% main_nodes)
to_trim<-row.names(to_trim)
from_trim<-row.names(from_trim)

#Extracting Mitch's connections Edges
mitch_from<-subset(edges_heroes, row.names(edges_heroes) %in% from_trim)
mitch_to<-subset(edges_heroes, row.names(edges_heroes) %in% to_trim)
mitch_edges<-data.frame(mitch_from,mitch_to)

# Based on inspection, looks like there may be some smaller subnetworks that are invisible. Thus, I'm going to trim any edges with a closeness >.1
# This should remove any subnet nodes

secret_subnets<-subset(hero_closeness,hero_closeness$.>.1)
to_trim<-subset(edges_heroes, edges_heroes$to %in% secret_subnets$hero)

from_trim<-subset(edges_heroes, edges_heroes$from %in% secret_subnets$hero)
to_trim<-row.names(to_trim)
from_trim<-row.names(from_trim)

#Removing nodes
node_heroes<-subset(node_heroes, hero %notin% main_nodes )

#Removing Edges
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% from_trim)
edges_heroes<-subset(edges_heroes, row.names(edges_heroes) %notin% to_trim)

# Recreating the graph
G6<-graph_from_data_frame(edges_heroes,directed=T,vertices=node_heroes)
few_connections = which(degree(G6) %in% c(0,1,2,3,4,5))
G6 = igraph::delete.vertices(G6, few_connections)


visIgraph(
  G6,
  idToLabel = TRUE,
  layout = "layout_nicely",
  physics = FALSE,
  smooth = FALSE,
  type = "square",
  randomSeed = NULL,
  layoutMatrix = NULL)


# Rexamining Closeness
hero_closeness<-closeness(G6) %>% data.frame()
hero_closeness$hero<-rownames(hero_closeness)
# Looks far better




##################################
# Degree Centrality

mean(degree(G6))
# Average of 64 connections!
median(degree(G6))
# Median of 26


deg_cent<-degree(G6)


# Creating a histogram of degrees

t1<-table(deg_cent)

# Degrees are discrete numbers, so, we'll use the relative frequency instead
relafreq_1 <- t1/sum(t1)

barplot(relafreq_1, xlab = "k", ylab = "Relative frequencies (%)", 
        main = "Figure 1: Degree distribution of Marvel Comics Universe",
        col = "orange")

##############################
# Eigenvector Centrality

hero_eig<-eigen_centrality(G5) %>% data.frame()


mean(hero_eig$vector)
# Average of 64 connections!
median(hero_eig$vector)
# Median of 26


##########################
# Creating the Final Table
deg_cent<-degree(G5)
t1<-deg_cent %>% data.frame()

t1$hero<-rownames(t1)
t1$degree_centrality<-t1$.
t1$.<-NULL

hero_closeness$closeness_centrality<-hero_closeness$.
hero_closeness$.<-NULL

t1<-left_join(t1,hero_closeness)


hero_eig$hero<-rownames(hero_eig)

t1<-left_join(t1,select(hero_eig,c('hero','vector')),by='hero')
t1<-t1 %>% rename('eigen_centrality'='vector')

t2<-t1[order('degree_centrality'),] 

t2<-t1[order(t1$degree_centrality, decreasing = TRUE), ]
t2$Rank<-c(1:nrow(t2))

View(t2)


