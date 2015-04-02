#!/usr/bin/env Rscript
library(ggplot2)
table <- read.table(commandArgs(TRUE)[1], header=FALSE, sep="\t", stringsAsFactors=FALSE)
table <- 1 + table[1]
quant <- quantile(table$V1,seq(from = 0, to = 1, by = 0.05))
plot <- ggplot(table, aes(x=V1)) + geom_histogram(binwidth=.2,colour="black",fill="white") + scale_x_sqrt(breaks=unique(round(quant,0)),expand=c(0,0)) + geom_density(aes(y=..count..), alpha=.05,fill="blue") + ylab("Number of Clusters") + xlab("Number of Reads")
ggsave(plot=plot, file=commandArgs(TRUE)[2], width=14, height=8,dpi=80)
