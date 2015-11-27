#!/usr/bin/env Rscript

library("phyloseq")
library("ggplot2")
library("scales")
library("grid")

rawdata <- read.table(commandArgs(TRUE)[1], header=TRUE, sep="\t", stringsAsFactors=FALSE)
otudata = as.matrix(rawdata[,seq(8,ncol(rawdata),by=2)])
rownames(otudata) <- paste0("OTU",1:nrow(otudata))
colnames(otudata) <- paste0("Sample",1:ncol(otudata))
taxdata = as.matrix(rawdata[,c(1:7)])
rownames(taxdata) <- rownames(otudata)
taxdata <- cbind(do.call(paste, c(rawdata[,c(1:commandArgs(TRUE)[4])],sep=" / ")),taxdata)
colnames(taxdata)[1] <- "Taxonomy"
Sdata = sample_data(data.frame(Sample=colnames(rawdata)[seq(8,length(colnames(rawdata)),by=2)],row.names=colnames(otudata), stringsAsFactors=FALSE))
OTU = otu_table(otudata, taxa_are_rows=TRUE)
TAX = tax_table(taxdata)

if(ncol(OTU) < 2) {
	text = paste("Need more than one sample in order to create a heatmap.\nIf more than one sample was selected,\n check if the names are unique.")
	ggplot() + annotate("text", x = 4, y = 25, size=8, label = text) + theme_bw() + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank())
	ggsave(file=commandArgs(TRUE)[2], width=12, height=12,dpi=160)
} else {
	physeq = phyloseq(OTU,TAX,Sdata)
	physeqF = tax_glom(physeq, commandArgs(TRUE)[3])
	
	count5k = sum(sample_sums(physeqF) >= 5000)
	
	if(count5k >= 2) {
		physeqF5k = prune_samples(sample_sums(physeqF)>=5000, physeqF)
		physeqF5kR = rarefy_even_depth(physeqF5k)
	} else {
		physeqF5kR = physeqF
	}
	
	if(ncol(otudata) <= 2) {
		if(commandArgs(TRUE)[5] == "order") {
			plot <- plot_heatmap(physeqF5kR, "RDA", "bray", "Sample", "Taxonomy", taxa.order=commandArgs(TRUE)[3])
		} else {
	                plot <- plot_heatmap(physeqF5kR, "RDA", "bray", "Sample", "Taxonomy")
		}
	} else {
		if(commandArgs(TRUE)[5] == "order") {
	        	plot <- plot_heatmap(physeqF5kR, "NMDS", "bray", "Sample", "Taxonomy", taxa.order=commandArgs(TRUE)[3])
		} else {
	        	plot <- plot_heatmap(physeqF5kR, "NMDS", "bray", "Sample", "Taxonomy")
		}
	}
	plot <- plot + theme(plot.margin = unit(c(0.3,0.3,1,1), "inch"), axis.text.y = element_text(size = 10), axis.text.x = element_text(size=10))
	ggsave(plot=plot, file=commandArgs(TRUE)[2], width=12, height=12,dpi=160)
}
