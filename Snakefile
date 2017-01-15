from itertools import groupby
from itertools import (takewhile,repeat)
from Bio.Phylo.PAML import codeml
from Bio.Align.Applications import MafftCommandline
from io import StringIO
from Bio import AlignIO
from Bio import SeqIO
import sys


def fasta_iter(fasta_name):


    fh = open(fasta_name)


    faiter = (x[1] for x in groupby(fh, lambda line: line[0] == ">"))

    for header in faiter:
        headerStr = header.__next__()[1:].strip().split()[0]
        # print(header)


        seq = "".join(s.strip() for s in faiter.__next__())

        yield (headerStr, seq)
def isTrinity(header):
    if all([header[0:2] == "TR","|c" in header,"_g" in header,"_i" in header]):
        return True
    else:
        print("Sorry, we only support Trinity assemblies as of now\nExiting now")
        sys.exit()
        """
        Remove this nonsense, just return False
        
        """



SAMPLES, = glob_wildcards("{sample}.fasta")
#TESTTT, = glob_wildcards("OG{sample}.fa")

#print(TESTTT)
#SAMPLES2, = glob_wildcards("all.pep.combined_{sample}.fasta")
#RESULTS, = glob_wildcards("Little/Results_{date}")
#ORTHOGROUP, = glob_wildcards("Alignments/OG{orthogroup}.fa")


#ORTHOGROUP, = glob_wildcards("Little/Results_"+RESULTS[0]+"/Alignments/OG{orthogroup}.fa")
#ORTHOGROUP, = glob_wildcards("Little/OG{orthogroup}.fa")

#place4File = "sequenceDir/"+OrthoFinderDir+"/Alignments/OG{orthogroup}.out"
#print(expand("Alignments/OG{orthogroup}.phy",orthogroup=ORTHOGROUP))
#print(RESULTS)
#print(ORTHOGROUP)
#FAMILIES, = glob_wildcards("Families/family_{fam}.fasta")
#print(FAMILIES)
rule final:
    input:dynamic("Families/family_{fam}_dir/family_{fam}.codon.phylip")
    #input:dynamic("Families/family_{fam}.aln")
    #input:dynamic("Families/family_{fam}_dir/M01237/family_{fam}.mcl")
    #input: expand("{sample}.trinity",sample=SAMPLES)

    #input:"Families/family_3523_dir/M8_family_3523.mcl"
    #input: dynamic("Families/family_{fam}.fasta")

    #input:
    #    dynamic("Families/family_{fam}.phy.trimmed"),
    #    dynamic("Families/family_{fam}.phy")
    #input:
        #trimmedFile=dynamic("Families/family_{fam}.aln.trimmed"),
        #columnFile=dynamic("Families/family_{fam}.aln.trimmed.column_file")
    #input:dynamic("Families/family_{fam}.fasta")

    #input:expand("Families/family_{fam}.aln",fam=FAMILIES)
    #input: "Families/"
    #input:"Temp/all.pep.combined_r90_SLX.fnodes"
    #input: "Temp/all.pep.combined.blastall.out"
    #input:expand("Temp/{sample}.longestIsoform.pep.fasta", sample=SAMPLES),expand("Temp/{sample}.longestIsoform.cds",sample=SAMPLES)
#        input:"LittleAlignments/"

    #input:expand("OrthoDir/{sample}.longestIsoform.newer.fasta",sample=SAMPLES)
    #input:expand("Alignments/OG{orthogroup}.phy",orthogroup=ORTHOGROUP)

    #input: "combined.txt"

    #input:expand("Alignments/OG{orthogroup}.fa",orthogroup=ORTHOGROUP)

    #input: expand("sequenceDir/"+OrthoFinderDir+"/Alignments/OG{orthogroup}.out", orthogroup=ORTHOGROUP)

    #input: expand("sequenceDir/{sample}.longestIsoform.pep.fasta", sample=SAMPLES)
    #input:expand("all.pep.combined_{sample2}.RAXML.out.tre", sample2=SAMPLES2)
    #Aqinput:

    #input: "all.pep.combined.blastall.out"

#NOTE
"""
    Before this we need to check the headers of the fasta file, clean them up, and determine if they are from
        Trinity

    For now we will just have transdecoder 2.0 as a requirements, since only 1.0 is on bioconda, until
        I find a workaround
"""

rule checkTrinity:
    input:
        "{sample}.fasta"
    output:
        "{sample}.trinity"
    run:
        for currentFile in range(len(output)):
            with open(output[currentFile], "w") as out:
                with open(input[currentFile]) as f:
                    for line in f:
                        if line[0] ==">":
                            isTrinity(line[1:-1])
                        out.write(line)


rule transdecoder:
    input:
        "{sample}.trinity"
    output:
        "{sample}.transdecoder.pep"
    shell:
        "TransDecoder.LongOrfs -t {input} -m 30;TransDecoder.Predict -t {input} --single_best_orf"
longIsoform_CDS_combined = {}
#THIS RULE WORKS, hopefully correctly.....

"""
From here down the transdecoder extension is wrong and needs to be changes to {sample}.transdecoder.pep

"""
rule longestIsoform:
    input:
        pep_before = expand("{sample}.pep.transdecoder",sample=SAMPLES),
        cds_before = expand("{sample}.cds.transdecoder",sample=SAMPLES)
    output:
        pep_after = expand("Temp/{sample}.longestIsoform.pep.fasta",sample=SAMPLES),
        cds_after = expand("Temp/{sample}.longestIsoform.cds",sample=SAMPLES)
    run:


        #print(input.pep_before)
        #print (output.pep_after)



        #print(input.pep_before)
        for currentFile in range(len(output.pep_after)):

            with open(output.pep_after[currentFile], "w") as out:
                longIsoform={}

                sequence_iterator = fasta_iter(input.pep_before[currentFile])
                sample = input.pep_before[currentFile].split('.')[0]
                for ff in sequence_iterator:

                    headerStr, seq = ff
                    GeneID = headerStr.split('::')[1][:-2]

                    if GeneID not in longIsoform:
                        longIsoform[GeneID] = [len(seq),headerStr,seq]
                    else:
                        if longIsoform[GeneID][0] < len(seq):
                            longIsoform[GeneID] = [len(seq),headerStr,seq]
                for i in longIsoform.keys():
                    #print("things")
                    #print(i)
                    #print(longIsoform[i][1])

                    out.write('>'+sample+'_'+longIsoform[i][1].split("::")[0]+'\n')
                    out.write(longIsoform[i][2]+'\n')





        for currentFile in range(len(output.cds_after)):
            with open(output.cds_after[currentFile], "w") as out:
                longIsoform_CDS ={}

                sequence_iterator = fasta_iter(input.cds_before[currentFile])
                sample = input.cds_before[currentFile].split('.')[0]
                for ff in sequence_iterator:

                    headerStr, seq = ff
                    GeneID = headerStr.split('::')[1][:-2]

                    if GeneID not in longIsoform_CDS:
                        longIsoform_CDS[GeneID] = [len(seq),headerStr,seq]
                    else:
                        if longIsoform_CDS[GeneID][0] < len(seq):
                            longIsoform_CDS[GeneID] = [len(seq),headerStr,seq]
                for i in longIsoform_CDS.keys():
                    #print("things")
                    #print(i)
                    #print(longIsoform[i][1])
                    out.write('>'+sample+'_'+longIsoform_CDS[i][1].split("::")[0]+'\n')
                    out.write(longIsoform_CDS[i][2]+'\n')
                    Header = sample+'_'+longIsoform_CDS[i][1].split("::")[0]
                    #this thing may be too unreasonably huge, but it will save time in the later rule
                    longIsoform_CDS_combined[Header]=longIsoform_CDS[i][2]


rule combine_pep:
    input:
        expand("Temp/{sample}.longestIsoform.pep.fasta",sample=SAMPLES)
    output:
        "Temp/all.pep.combined"

    run:

        with open(output[0], "w") as out:
            for i in input:
                sample = i.split('.')[0]
                for line in open(i):
                    # if ">" in line:
                    #     out.write(">"+sample+"_"+line.strip(">"))
                    # else:
                    out.write(line)



rule blastall:
    input:
        "Temp/all.pep.combined"
    output:
        "Temp/all.pep.combined.blastall.out"
    shell:
        """
        makeblastdb -in {input} -out {input}.seq.db -dbtype prot
        blastp -db {input}.seq.db -query {input} -outfmt 6 -out {output} -num_threads 13 -evalue 1E-5
        """

rule silix:
    input:
        sequence_file="Temp/all.pep.combined",
        blast_file = "Temp/all.pep.combined.blastall.out"
    output:
        "Temp/all.pep.combined_r90_SLX.fnodes"
    shell:
        "silix -r 0.9 {input.sequence_file} {input.blast_file} > {output} || true"

"""

This is the first appearance of {fam} from dynamic,

    Since not all families are kept for downstream analysis, we should only keep the ones that don't become empty after nogaps
        the empty ones are determined from mafft,so that would probably have to be in this rule under some os() thingy
            the fasta files can be written as a side effect with "EMPTYALIGNMENt" or something in the node2families
                so that the sequences are still there physically
                put in log file that these families suck

"""




rule node2families:
    input:
        node_file="Temp/all.pep.combined_r90_SLX.fnodes",
        sequence_file="Temp/all.pep.combined"
    output:
        dynamic("Families/family_{fam}.aln")
    run:


            famDict = {}
            seqDict={}
            print("opening",input.node_file)
            with open(input.node_file) as f:
                for line in f:
                    row = line.split()
                    if row[0] not in famDict:
                        famDict[row[0]]= [row[1]]

                    else:
                        famDict[row[0]].append(row[1])

            sequence_iterator = fasta_iter(input.sequence_file)

            for ff in sequence_iterator:
                headerStr, seq = ff

                seqDict[headerStr] = seq


            for i in famDict.keys():
                if len(famDict[i])>14:
                    String = "Families/family_"+i+".fasta"
                    print(String)

                    with open(String, "w") as out:
                        for j in famDict[i]:
                            out.write('>'+j+'\n')
                            out.write(seqDict[j]+'\n')


                    mafft_cline = MafftCommandline(input=String,auto=True)
                    stdout, stderr = mafft_cline()
                    align = AlignIO.read(StringIO(stdout), "fasta")

                    sequence={}
                    alignLength = align.get_alignment_length()
                    gapPos = {}

                    for i in range(len(align._records)):
                        sequence[i]=""
                        number = 0
                        for j in align._records[i]:
                            sequence[i]+=j
                            if j == "-":
                                gapPos[number]= True
                            number+=1
                    colsWithGaps = len(gapPos)
                    if colsWithGaps < alignLength:
                        AlignOut = String[0:-5]+"aln"
                        count = SeqIO.write(align, AlignOut, "fasta")




#
# rule mafft:
#     input:
#         "Families/family_{fam}.fasta"
#     output:
#         "Families/family_{fam}.aln"
#     shell:
#         "mafft --auto --thread -1 {input} > {output}"
#

rule trimAln:
    input:
        "Families/family_{fam}.aln"
    output:
        trimmed_file="Families/family_{fam}.aln.trimmed",
        column_file="Families/family_{fam}.aln.trimmed.column_file"
    shell:
        "trimal -in {input} -out {output.trimmed_file} -nogaps -colnumbering > {output.column_file}"##




rule aln2phy:
    input:
        "Families/family_{fam}.aln",
        "Families/family_{fam}.aln.trimmed"
    output:
        "Families/family_{fam}.phy",
        "Families/family_{fam}.phy.trimmed"
    run:
        seq_length=0
        #print(output,"is output")
        #print(input,"is input")
        for currentFile in range(len(output)):
            print(output[currentFile],input[currentFile])

            with open(output[currentFile], "w") as out:


                sequence_iterator = fasta_iter(input[currentFile])
                first_line =True
                for ff in sequence_iterator:

                    headerStr, seq = ff
                    if first_line:
                        seq_length = len(seq)
                        num_lines = num_lines = sum(1 for line in open(input[currentFile]) if line[0]=='>')
                        out.write(str(num_lines)+" "+str(seq_length)+"\n")
                        first_line=False

                    seq_length = len(seq)
                    out.write(headerStr.strip('>')+"\t")
                    out.write(seq +"\n")

#print(longIsoform_CDS_combined)
rule phy2codon:
    input:
        untrimmed="Families/family_{fam}.phy",
        column_file="Families/family_{fam}.aln.trimmed.column_file",
        nucleotide=expand("Temp/{sample}.longestIsoform.cds",sample=SAMPLES)
    output:
        "Families/family_{fam}_dir/family_{fam}.codon.phylip"
    run:
        cut = ""
        print(input.untrimmed)
        print(input.column_file)
        print(input.nucleotide)
        print(output)
        if longIsoform_CDS_combined == {}:
            print("making cds dictionary")
            for currentFile in input.nucleotide:
                #with open(output.cds_after[currentFile], "w") as out:
                    # longIsoform_CDS ={}

                sequence_iterator = fasta_iter(currentFile)
                    #sample = input.cds_before[currentFile].split('.')[0]
                for ff in sequence_iterator:

                    headerStr, seq = ff
                    GeneID = headerStr

                    if GeneID not in longIsoform_CDS_combined:
                            longIsoform_CDS_combined[GeneID] = seq
        #Open outout
        #print(longIsoform_CDS_combined)
        with open(output[0], "w") as out:


            #Get  column cut file
            with open(input.column_file) as f:
                for line in f:
                    cut  +=line.strip()
                cut = cut.split(',')
                cut = list(map(int, cut))
            #print(cut)

            #Get corresponding untrimmed Alignments, as original, line by line
            line1=True
            first_line=True
            with open(input.untrimmed) as f:
                for line in f:
                    if line1:

                        line1=False
                        continue

                    row =line.strip().split()
                    # print("***********")
                    # print(row)
                    # print("____________")
                    original=row[1]#cds
                    header=row[0]
                    #print("Sequence:",sequence)
                    #print("Header:",header)
                    sequence=longIsoform_CDS_combined[header]#original
                    CodonPos={}
                    position=0
                    codon=""
                    number=1
                    for i in sequence:

                        codon +=i
                        #print i,position%3,codon
                        if position%3==2:
                            #print codon
                            #print codonTable[codon]
                            CodonPos[number]=codon
                            number+=1
                            #protein+=codonTable[codon]
                        position +=1

                        if position%3==0:
                            #print codon
                            codon=""
                    aaPos=0
                    firstAA=True
                    alnPos=0
                    prot=""
                    trimmed=""
                    for i in original:
                        if i!="-":
                            aaPos+=1

                        if alnPos in cut:
                            prot+=i
                            if i != "-":
                                trimmed+=CodonPos[aaPos]
                            else:
                                trimmed+="---"
                        alnPos+=1
                    num_lines = sum(1 for line in open(input.untrimmed) )
                    if first_line:
                        out.write(str(num_lines-1) + " " + str(len(trimmed)) + '\n')
                        first_line=False
                    out.write(header+'   '+trimmed+'\n')
rule FastTree:
    input:
        "Families/family_{fam}.aln.trimmed"
    output:
        "Families/family_{fam}_dir/family_{fam}.tree"
    shell:
        "FastTree  -nosupport {input} > {output} || true"

rule copyTreeAln:
    input:
        tree_before="Families/family_{fam}_dir/family_{fam}.tree",
        aln_before="Families/family_{fam}_dir/family_{fam}.codon.phylip"
    output:
        treeM8= "Families/family_{fam}_dir/M8/family_{fam}.tree",
        treeM01237="Families/family_{fam}_dir/M01237/family_{fam}.tree",
        alnM8 = "Families/family_{fam}_dir/M8/family_{fam}.codon.phylip",
        alnM01237="Families/family_{fam}_dir/M01237/family_{fam}.codon.phylip"
    shell:
        """cp {input.tree_before} {output.treeM8}
        cp {input.tree_before} {output.treeM01237}
        cp {input.aln_before} {output.alnM8}
        cp {input.aln_before} {output.alnM01237}
        """



###############################################################
"""

for PAML rule,

    have 2 outputs, M8 and M01237
    also an out put file with the following columns
        GeneFamily  ModelComparison ChiSq D.F p-value maybeFDR
    Also,, try to generate all BEB files that exist (a lot of times they don't)
        We'll use these in the final rule to plot familes with sites of strong selection


"""






#####################################################################3
rule makeCodmlFile:
    input:
        tree="Families/family_{fam}_dir/M01237/family_{fam}.tree",
        codonAlignment = "Families/family_{fam}_dir/M01237/family_{fam}.codon.phylip"
    output:
        "Families/family_{fam}_dir/M01237/family_{fam}.mcl"
    run:

        M8_cml = codeml.Codeml()
        M8_cml.alignment = input.codonAlignment
        M8_cml.tree = input.tree
        M8_cml.out_file = output[0]
        M8_cml.working_dir = output[0].split('/')[:-1][0] +'/'+output[0].split('/')[:-1][1]+'/'+output[0].split('/')[:-1][2]+'/'


        M8_cml.set_options(noisy = 9)	         # 0,1,2,3,9: how much rubbish on the screen
        M8_cml.set_options(verbose = 1)	     # 1: detailed output, 0: concise output
        M8_cml.set_options(runmode = 0)	     # 0: user tree;  1: semi-automatic;  2: automatic
        M8_cml.set_options(seqtype = 1)	     # 1:codons; 2:AAs; 3:codons-->AAs
        M8_cml.set_options(CodonFreq = 2)	     # 0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table
        M8_cml.set_options(clock = 0)	         # 0: no clock, unrooted tree, 1: clock, rooted tree
        M8_cml.set_options(aaDist = 0)	         # 0:equal, +:geometric; -:linear, {1-5:G1974,Miyata,c,p,v}
        M8_cml.set_options(model = 0)	         # models for codons:
        M8_cml.set_options(NSsites = [8])	     # 0:one w; 1:NearlyNeutral; 2:PositiveSelection; 3:discrete; Needs to be array
        M8_cml.set_options(icode = 0)	         # 0:standard genetic code; 1:mammalian mt; 2-10:see below
        M8_cml.set_options(Mgene = 0)	         # 0:rates, 1:separate; 2:pi, 3:kappa, 4:all
        M8_cml.set_options(fix_kappa = 0)	     # 1: kappa fixed, 0: kappa to be estimated
        M8_cml.set_options(kappa = 2)	         # initial or fixed kappa
        M8_cml.set_options(fix_omega = 1)	     # 1: omega or omega_1 fixed, 0: estimate
        M8_cml.set_options(omega = 1)	         # initial or fixed omega, for codons or codon-based AAs
        M8_cml.set_options(getSE = 0)	         # 0: don't want them, 1: want S.E.s of estimates
        M8_cml.set_options(RateAncestor = 0)	 # (0,1,2): rates (alpha>0) or ancestral states (1 or 2)
        M8_cml.set_options(Small_Diff = .45e-6) # Default value.
        M8_cml.set_options(cleandata = 0)	     # remove sites with ambiguity data (1:yes, 0:no)?
        M8_cml.set_options(fix_blength = 0)	 # 0: ignore, -1: random, 1: initial, 2: fixed


        M8_results=M8_cml.run(verbose=True)

        M8a_lnL=M8_results.get("NSsites").get(8).get("lnL")
        M8a_paramList= M8_results.get("NSsites").get(8).get("parameters").get("parameter list").split()
        M8a_np = len(M8a_paramList)



            #
            # try:
            #     M8_cml.run(verbose=True)
            # except:
            #     ctlFile = output[0].split('/')[:-1][0] +'/'+output[0].split('/')[:-1][1]+'/'+"codeml.ctl"
            #     M8_cml.ctl_file = ctlFile
            #     M8_cml.write_ctl_file()
            #     with open(output[0], "w") as out:
            #         out.write("EMPTY alignment")
        M01237_cml = codeml.Codeml()
        M01237_cml.alignment = input.codonAlignment
        M01237_cml.tree = input.tree
        M01237_cml.out_file = output[0]
        M01237_cml.working_dir = output[0].split('/')[:-1][0] +'/'+output[0].split('/')[:-1][1]+'/'+output[0].split('/')[:-1][2]+'/'


        M01237_cml.set_options(noisy = 9)	         # 0,1,2,3,9: how much rubbish on the screen
        M01237_cml.set_options(verbose = 1)	     # 1: detailed output, 0: concise output
        M01237_cml.set_options(runmode = 0)	     # 0: user tree;  1: semi-automatic;  2: automatic
        M01237_cml.set_options(seqtype = 1)	     # 1:codons; 2:AAs; 3:codons-->AAs
        M01237_cml.set_options(CodonFreq = 2)	     # 0:1/61 each, 1:F1X4, 2:F3X4, 3:codon table
        M01237_cml.set_options(clock = 0)	         # 0: no clock, unrooted tree, 1: clock, rooted tree
        M01237_cml.set_options(aaDist = 0)	         # 0:equal, +:geometric; -:linear, {1-5:G1974,Miyata,c,p,v}
        M01237_cml.set_options(model = 0)	         # models for codons:
        M01237_cml.set_options(NSsites = [0,1,2,3,7,8])	     # 0:one w; 1:NearlyNeutral; 2:PositiveSelection; 3:discrete; Needs to be array
        M01237_cml.set_options(icode = 0)	         # 0:standard genetic code; 1:mammalian mt; 2-10:see below
        M01237_cml.set_options(Mgene = 0)	         # 0:rates, 1:separate; 2:pi, 3:kappa, 4:all
        M01237_cml.set_options(fix_kappa = 0)	     # 1: kappa fixed, 0: kappa to be estimated
        M01237_cml.set_options(kappa = 2)	         # initial or fixed kappa
        M01237_cml.set_options(fix_omega = 0)	     # 1: omega or omega_1 fixed, 0: estimate
        M01237_cml.set_options(omega = 1)	         # initial or fixed omega, for codons or codon-based AAs
        M01237_cml.set_options(getSE = 0)	         # 0: don't want them, 1: want S.E.s of estimates
        M01237_cml.set_options(RateAncestor = 0)	 # (0,1,2): rates (alpha>0) or ancestral states (1 or 2)
        M01237_cml.set_options(Small_Diff = .45e-6) # Default value.
        M01237_cml.set_options(cleandata = 0)	     # remove sites with ambiguity data (1:yes, 0:no)?
        M01237_cml.set_options(fix_blength = 0)	 # 0: ignore, -1: random, 1: initial, 2: fixed


        M01237_results = M01237_cml.run(verbose=True)

        M0_lnL = M01237_results.get("NSsites").get(0).get("lnL")
        M0_np = len(M01237_results.get("NSsites").get(0).get("parameters").get("parameter list").split())

        M1a_lnL = M01237_results.get("NSsites").get(1).get("lnL")
        M1a_np = len(M01237_results.get("NSsites").get(1).get("parameters").get("parameter list").split())

        M2a_lnL = M01237_results.get("NSsites").get(2).get("lnL")
        M2a_np = len(M01237_results.get("NSsites").get(2).get("parameters").get("parameter list").split())

        M3_lnL = M01237_results.get("NSsites").get(3).get("lnL")
        M3_np = len(M01237_results.get("NSsites").get(3).get("parameters").get("parameter list").split())

        M7_lnL = M01237_results.get("NSsites").get(7).get("lnL")
        M7_np = len(M01237_results.get("NSsites").get(7).get("parameters").get("parameter list").split())

        M8_lnL = M01237_results.get("NSsites").get(8).get("lnL")
        M8_np = len(M01237_results.get("NSsites").get(8).get("parameters").get("parameter list").split())

        ####test M3-M0

        M3_M0 = 2*(M3_lnL-M0_lnL)
        df_M3_M0 = M3_np - M0_np
        print(M3_M0)
        if M3_M0 >=0:
            print("P",cdf_chi2(df_M3_M0,M3_M0))

        ##test M2a-M1a

        M2a_M1a = 2*(M2a_lnL-M1a_lnL)
        df_M2a_M1a = M2a_np - M1a_np

        print(M2a_M1a)
        if M2a_M1a >=0:
            print("P",cdf_chi2(df_M2a_M1a,M2a_M1a))

        ## test M8-M7

        M8_M7 = 2*(M8_lnL-M7_lnL)
        df_M8_M7 = M8_np - M7_np
        print(M8_M7)
        if M8_M7 >= 0:
            print("P",cdf_chi2(df_M8_M7,M8_M7))

        #test M8 - M8a

        M8_M8a = 2*(M8_lnL-M8a_lnL)
        df_M8_M8a = M8_np - M8a_np
        print(M8_M8a)
        if M8_M8a >=0:
            print("P",cdf_chi2(df_M8_M8a,M8_M8a))




        # try:
        #     M01237_cml.run(verbose=True)
        # except:
        #     ctlFile = output[0].split('/')[:-1][0] +'/'+output[0].split('/')[:-1][1]+'/'+output.split('/')[:-1][2]+'/'+"codemlM01237.ctl"
        #     M01237_cml.ctl_file = ctlFile
        #     M01237_cml.write_ctl_file()
        #     with open(output[0], "w") as out:
        #         out.write("EMPTY alignment")

########A sketch for how to get needed data from end of rst file
"""
linesToPrint =""
keepGoing=False
BEB_found= False
DATA_found = False
with open("BEB.txt") as f:
    for line in f:
        # if keepGoing:
        #     linesToPrint+=line
        if "BEB" in line and "11" in line :
            # linesToPrint+=line
            BEB_found = True
        if BEB_found:
            if DATA_found == False:
                try:
                    if line.split()[1] in "ACDEFGHIKLMNPQRSTVWY":
                        linesToPrint+=line
                        DATA_found = True
                except:
                    0
            else:
                try:
                    if line.split()[1] in "ACDEFGHIKLMNPQRSTVWY":
                        linesToPrint +=line
                except:
                    print linesToPrint
                    break


"""
