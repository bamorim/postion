import { check, sleep } from "k6";
import http from "k6/http";
import { htmlReport } from "https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js";
import { textSummary } from "https://jslib.k6.io/k6-summary/0.0.1/index.js";
import { randomItem } from "https://jslib.k6.io/k6-utils/1.2.0/index.js";

const baseUrl = "http://localhost:4000";

function getTopicId(doc, title) {
  const topics = doc.find("#topics tr td");
  const problemTopic = topics.filter((_idx, el) => el.text().trim() == title);
  return problemTopic.parent("tr").attr("id").split("-")[1];
}

function getTopicIds(doc) {
  return doc.find("#topics tr").map((_idx, el) => el.attr("id").split("-")[1]);
}

function getPostIds(doc) {
  return doc.find("#posts tr").map((_idx, el) => el.attr("id").split("-")[1]);
}

function collectTopicIds(topic_ids, level) {
  if (level >= 2) return [];
  return topic_ids.flatMap((id) => {
    const doc = http.get(http.url`${baseUrl}/topics/${id}`).html();
    return [id, ...collectTopicIds(getTopicIds(doc), level + 1)];
  });
}

let hugeTopicId, hugePostId, topicIds;
let initialized = false;

// Just to give 80% change to a random topic+post
let randomActions = Array(8)
  .fill()
  .map((_) => "RANDOM");

let actions = ["HUGE_TOPIC", "HUGE_POST", ...randomActions];

// Entrypoints
export default function () {
  let response = http.get(http.url`${baseUrl}/`);

  // Login if needed
  if (response.url == `${baseUrl}/users/log_in`) {
    response = response.submitForm({
      formSelector: "#login_form",
      fields: {
        "user[email]": "demo@example.com",
        "user[password]": "123412341234",
      },
    });
  }

  if (!initialized) {
    console.log("Initializing...");
    let doc = response.html();
    const problemTopicId = getTopicId(doc, "99 Problems");
    const rootTopicIds = doc
      .find("#topics tr")
      .map((_idx, el) => el.attr("id").split("-")[1]);

    response = http.get(http.url`${baseUrl}/topics/${problemTopicId}`);
    doc = response.html();
    hugeTopicId = getTopicId(doc, "Huge Topic");
    hugePostId = doc.find("#posts tr").attr("id").split("-")[1];
    topicIds = collectTopicIds(rootTopicIds, 0);
    initialized = true;
  } else {
    console.log("Initialized...");
    switch (randomItem(actions)) {
      case "HUGE_TOPIC":
        console.log("Opening Huge Topic");
        http.get(http.url`${baseUrl}/topics/${hugeTopicId}`);
        break;
      case "HUGE_POST":
        console.log("Opening Huge Post");
        http.get(http.url`${baseUrl}/posts/${hugePostId}`);
        break;
      case "RANDOM":
        const topicId = randomItem(topicIds);
        console.log(`Opening Topic #${topicId}`);
        const postIds = getPostIds(
          http.get(http.url`${baseUrl}/topics/${topicId}`).html()
        );
        if (postIds.length > 0) {
          const postId = randomItem(postIds);
          console.log(`Opening Post #${postId}`);
          http.get(http.url`${baseUrl}/posts/${postId}`);
        } else {
          console.log("Topic Empty");
        }
    }
  }
}

export function handleSummary(data) {
  return {
    "result.html": htmlReport(data),
    stdout: textSummary(data, { indent: " ", enableColors: true }),
  };
}
