#!/usr/bin/env python
import plyvel
import os
import time
from os.path import expanduser
import argparse
import sys


# functions
def write(out, query, result):
    out.write("%s\t%s\n" % (query, result))


def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ("yes", "true", "t", "y", "1"):
        return True
    elif v.lower() in ("no", "false", "f", "n", "0"):
        return False
    else:
        raise argparse.ArgumentTypeError("Boolean value expected!")


def getAll(
    input,
    alen,
    evalue,
    bitscore,
    identity,
    queryCol,
    subjectCol,
    evalueCol,
    bitscoreCol,
    alenCol,
    pidentCol,
    db,
    out,
    unknown,
    sep,
):
    check = True
    query = None
    with open(input, "r") as f:
        write(out, "Query", "Annotation")
        for line in f:
            ls = line.split(sep)
            if check:
                lastIndexOfInterest = max(queryCol, subjectCol, evalueCol, bitscoreCol, alenCol, pidentCol)
                if len(ls) < 6:
                    print(
                        "Error: invalid number of columns!\n"
                        + input
                        + " has "
                        + str(len(ls))
                        + " columns and at least 6 columns are required!"
                    )
                    break
                elif len(ls) <= lastIndexOfInterest:
                    print(
                        "Error: invalid number of columns!\n"
                        + input
                        + " has "
                        + str(len(ls))
                        + " columns and the last index of interest is "
                        + str(lastIndexOfInterest)
                        + "!"
                    )
                    break
                else:
                    check = False
            query = ls[queryCol]
            if not checkHit(ls, alen, evalue, bitscore, identity, alenCol, evalueCol, bitscoreCol, pidentCol):
                if unknown:
                    write(out, query, "Unknown")
                continue
            result = db.get(ls[subjectCol].strip().encode())
            if result == None:
                if unknown:
                    write(out, query, "Unknown")
                continue
            result = result.decode()
            write(out, query, result)


def getBestHits(
    input,
    alen,
    evalue,
    bitscore,
    identity,
    queryCol,
    subjectCol,
    evalueCol,
    bitscoreCol,
    alenCol,
    pidentCol,
    db,
    out,
    unknown,
    sep,
):
    firstQuery = True
    match = False
    check = True
    query = None
    with open(input, "r") as f:
        write(out, "Query", "Annotation")
        for line in f:
            ls = line.split(sep)
            if check:
                lastIndexOfInterest = max(queryCol, subjectCol, evalueCol, bitscoreCol, alenCol, pidentCol)
                if len(ls) < 6:
                    print(
                        "Error: invalid number of columns!\n"
                        + input
                        + " has "
                        + str(len(ls))
                        + " columns and at least 6 columns are required!"
                    )
                    break
                elif len(ls) <= lastIndexOfInterest:
                    print(
                        "Error: invalid number of columns!\n"
                        + input
                        + " has "
                        + str(len(ls))
                        + " columns and the last index of interest is "
                        + str(lastIndexOfInterest)
                        + "!"
                    )
                    break
                else:
                    check = False
            if firstQuery:
                query = ls[queryCol]
                firstQuery = False
            if match:
                if query == ls[queryCol]:
                    continue
                else:
                    match = False
                    query = ls[queryCol]
            else:
                if query != ls[queryCol]:
                    if unknown:
                        write(out, query, "Unknown")
                    query = ls[queryCol]
            if not checkHit(ls, alen, evalue, bitscore, identity, alenCol, evalueCol, bitscoreCol, pidentCol):
                continue
            result = db.get(ls[subjectCol].strip().encode())
            if result == None:
                continue
            result = result.decode()
            write(out, query, result)
            match = True
    if not match:
        if unknown:
            write(out, query, "Unknown")


def checkHit(ls, alen, evalue, bitscore, identity, alenCol, evalueCol, bitscoreCol, pidentCol):
    if float(ls[pidentCol]) < identity:
        return False
    elif int(ls[alenCol]) < alen:
        return False
    elif float(ls[evalueCol]) > evalue:
        return False
    elif float(ls[bitscoreCol]) < bitscore:
        return False
    return True


def createLevelDB(input, key, value, sep, header, db):
    with open(input, "r") as f:
        for line in f:
            ls = line.split(sep)
            if header:
                header = False
                continue
            db.put(ls[key].strip().encode(), ls[value].strip().encode())


# help
parser = argparse.ArgumentParser(
    description="Annotate each query using the best alignment for which a mapping is known"
)
parser.add_argument("-v", "--version", action="version", version="Annotate 1.0")
subparsers = parser.add_subparsers(help="Sub-command help", dest="subparser_name")

createdb_parser = subparsers.add_parser("createdb", description="Create/Update a mapping database")
createdb_parser.add_argument("input", help="A mapping file containing at least two columns")
createdb_parser.add_argument("output", help="LevelDB prefix")
createdb_parser.add_argument("key", help="Column index (0-based) in which the keys can be found", type=int)
createdb_parser.add_argument("value", help="Column index (0-based) in which the values can be found", type=int)
createdb_parser.add_argument("--sep", help="The separator between columns (default: \\t)", default="\t")
createdb_parser.add_argument(
    "--header", help="Indicates the presence of a header in the input file (default: True)", type=str2bool, default=True
)
createdb_parser.add_argument(
    "-d", "--directory", help="Directory of databases (default: $HOME/.annotate/levelDB)", default="home"
)

idmapping_parser = subparsers.add_parser(
    "idmapping", description="Translate identifiers from the input using the mapping database"
)
idmapping_parser.add_argument("input", help="A BLAST/DIAMOND result in tabular format")
idmapping_parser.add_argument("output", help="Output filename")
idmapping_parser.add_argument("ldb", help="LevelDB prefix")
idmapping_parser.add_argument(
    "-b",
    "--bitscore",
    help="Minimum bit score of a hit to be considered good (default: 50.0)",
    type=float,
    default=50.0,
)
idmapping_parser.add_argument(
    "-e",
    "--evalue",
    help="Maximum e-value of a hit to be considered good (default: 0.00001)",
    type=float,
    default=0.00001,
)
idmapping_parser.add_argument(
    "-l", "--alen", help="Minimum alignment length of a hit to be considered good (default: 50)", type=int, default=50
)
idmapping_parser.add_argument(
    "-i",
    "--identity",
    help="Minimum percent identity of a hit to be considered good (default: 80)",
    type=float,
    default=80,
)
idmapping_parser.add_argument(
    "-d", "--directory", help="Directory of databases (default: $HOME/.annotate/levelDB)", default="home"
)
idmapping_parser.add_argument(
    "--queryCol", help="Column index (0-based) in which the query ID can be found (default: 0)", type=int, default=0
)
idmapping_parser.add_argument(
    "--subjectCol", help="Column index (0-based) in which the subject ID can be found (default: 1)", type=int, default=1
)
idmapping_parser.add_argument(
    "--evalueCol", help="Column index (0-based) in which the e-value can be found (default: 10)", type=int, default=10
)
idmapping_parser.add_argument(
    "--bitscoreCol",
    help="Column index (0-based) in which the bit score can be found (default: 11)",
    type=int,
    default=11,
)
idmapping_parser.add_argument(
    "--alenCol",
    help="Column index (0-based) in which the alignment length can be found (default: 3)",
    type=int,
    default=3,
)
idmapping_parser.add_argument(
    "--pidentCol",
    help="Column index (0-based) in which the percent identity can be found (default: 2)",
    type=int,
    default=2,
)
idmapping_parser.add_argument("--all", help="Try to annotate all hits (default: False)", type=str2bool, default=False)
idmapping_parser.add_argument(
    "--unknown",
    help="Whether to write 'Unknown' in the output for unknown mappings (default: True)",
    type=str2bool,
    default=True,
)
idmapping_parser.add_argument("--sep", help="The separator between columns (default: \\t)", default="\t")

fixplyvel = subparsers.add_parser("fixplyvel", description="Fix plyvel undefined symbol error by reinstalling it")
args = parser.parse_args()

# check args
if args.subparser_name == "idmapping" or args.subparser_name == "createdb":
    if not os.path.isfile(args.input):
        print("Error: " + args.input + " is not a file or does not exist!")
        sys.exit()
    if args.directory == "home":
        databasehome = os.path.join(expanduser("~"), ".annotate/levelDB")
        if not os.path.isdir(databasehome):
            os.makedirs(databasehome)
            print("Database directory created at " + databasehome + "!")
    else:
        if not os.path.isdir(args.directory):
            print("Error: database directory not found!\n" + args.directory + " is not a directory or does not exist!")
            sys.exit()
if args.subparser_name == "createdb":
    if args.directory == "home":
        dbdir = os.path.join(databasehome, str(args.output + ".ldb"))
    else:
        dbdir = os.path.join(args.directory, str(args.output + ".ldb"))
    print("Creating database, this may take some time...")
    db = plyvel.DB(dbdir, create_if_missing=True)
    start_time = time.time()
    createLevelDB(args.input, args.key, args.value, args.sep, args.header, db)
    db.close()
    print("Done!")
    elapsed_time = time.time() - start_time
    print("Time: " + str(elapsed_time) + " seconds.")
elif args.subparser_name == "idmapping":
    if args.directory == "home":
        dbdir = os.path.join(databasehome, str(args.ldb + ".ldb"))
        if not os.path.isdir(dbdir):
            print("Error: database not found!\n" + dbdir + " is not a directory or does not exist!")
            sys.exit()
    else:
        dbdir = os.path.join(args.directory, str(args.ldb + ".ldb"))
        if not os.path.isdir(dbdir):
            print("Error: database not found!\n" + dbdir + " is not a directory or does not exist!")
            sys.exit()
    db = plyvel.DB(dbdir, create_if_missing=False)
    out = open(args.output, "w")
    start_time = time.time()
    print("Annotating queries, this may take some time...")
    if args.all:
        getAll(
            args.input,
            args.alen,
            args.evalue,
            args.bitscore,
            args.identity,
            args.queryCol,
            args.subjectCol,
            args.evalueCol,
            args.bitscoreCol,
            args.alenCol,
            args.pidentCol,
            db,
            out,
            args.unknown,
            args.sep,
        )
    else:
        getBestHits(
            args.input,
            args.alen,
            args.evalue,
            args.bitscore,
            args.identity,
            args.queryCol,
            args.subjectCol,
            args.evalueCol,
            args.bitscoreCol,
            args.alenCol,
            args.pidentCol,
            db,
            out,
            args.unknown,
            args.sep,
        )
    out.close()
    db.close()
    print("Done!")
    elapsed_time = time.time() - start_time
    print("Time: " + str(elapsed_time) + " seconds.")
elif args.subparser_name == "fixplyvel":
    os.system("pip3 install -U plyvel --no-cache-dir --no-deps --force-reinstall")
else:
    parser.print_help()
